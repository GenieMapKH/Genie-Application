import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium_libs/sodium_libs.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'crypto_service.dart';

/// Stores each account's identity key pair on this device.
///
/// Keys are kept per user id: signing in as someone else on the same device
/// must never reuse, or publish, the previous user's private key.
class KeyService {
  final FlutterSecureStorage secureStorage;
  final CryptoService cryptoService;
  final Dio dio;

  KeyService({
    required this.cryptoService,
    required this.dio,
    this.secureStorage = const FlutterSecureStorage(),
  });

  /// Where the single, per-device key pair was kept before keys were stored
  /// per account. See [adoptLegacyKeyPair].
  static const _legacyPublicKeyKey = 'identity_public_key';
  static const _legacyPrivateKeyKey = 'identity_private_key';

  String _publicKeyKey(String userId) => '${_legacyPublicKeyKey}_$userId';
  String _privateKeyKey(String userId) => '${_legacyPrivateKeyKey}_$userId';

  /// The key pair read last, so a chat does not hit secure storage for
  /// every message.
  ({String userId, KeyPair keyPair})? _loaded;

  /// Checks if the identity key pair exists locally
  Future<bool> hasLocalKeyPair(String userId) async {
    final pubKeyBase64 = await secureStorage.read(key: _publicKeyKey(userId));
    final privKeyBase64 = await secureStorage.read(key: _privateKeyKey(userId));
    return pubKeyBase64 != null && privKeyBase64 != null;
  }

  /// Returns the existing identity key pair, or null if it doesn't exist
  Future<KeyPair?> getIdentityKeyPair(String userId) async {
    final loaded = _loaded;
    if (loaded != null && loaded.userId == userId) return loaded.keyPair;

    final pubKeyBase64 = await secureStorage.read(key: _publicKeyKey(userId));
    final privKeyBase64 = await secureStorage.read(key: _privateKeyKey(userId));
    if (pubKeyBase64 == null || privKeyBase64 == null) return null;

    final keyPair = KeyPair(
      publicKey: base64Decode(pubKeyBase64),
      secretKey: SecureKey.fromList(
        cryptoService.sodium,
        base64Decode(privKeyBase64),
      ),
    );
    _loaded = (userId: userId, keyPair: keyPair);
    return keyPair;
  }

  /// Generates a new identity key pair and saves it securely
  Future<KeyPair> generateAndSaveIdentityKeyPair(String userId) async {
    final keyPair = cryptoService.generateKeyPair();
    await saveIdentityKeyPair(userId, keyPair);
    return keyPair;
  }

  /// Stores the identity key pair rebuilt from a decrypted backup.
  /// Throws if the secret key does not belong to [publicKey].
  Future<void> restoreIdentityKeyPair(
    String userId, {
    required Uint8List publicKey,
    required List<int> secretKeyBytes,
  }) {
    final secretKey = cryptoService.sodium.secureCopy(
      Uint8List.fromList(secretKeyBytes),
    );
    if (!cryptoService.isKeyPair(publicKey, secretKey)) {
      throw StateError('Backup does not match the registered public key');
    }
    return saveIdentityKeyPair(
      userId,
      KeyPair(publicKey: publicKey, secretKey: secretKey),
    );
  }

  /// Saves a specific key pair to secure storage (e.g., after backup restore)
  Future<void> saveIdentityKeyPair(String userId, KeyPair keyPair) async {
    await secureStorage.write(
      key: _publicKeyKey(userId),
      value: base64Encode(keyPair.publicKey),
    );
    await secureStorage.write(
      key: _privateKeyKey(userId),
      value: base64Encode(keyPair.secretKey.extractBytes()),
    );
    _loaded = (userId: userId, keyPair: keyPair);
  }

  /// Moves the old per-device key pair to [userId], but only when the server
  /// lists that public key as theirs. Returns whether it was adopted.
  Future<bool> adoptLegacyKeyPair(String userId) async {
    final publicKey = await secureStorage.read(key: _legacyPublicKeyKey);
    final privateKey = await secureStorage.read(key: _legacyPrivateKeyKey);
    if (publicKey == null || privateKey == null) return false;
    if (await _fetchServerPublicKey(userId) != publicKey) return false;

    await secureStorage.write(key: _publicKeyKey(userId), value: publicKey);
    await secureStorage.write(key: _privateKeyKey(userId), value: privateKey);
    await secureStorage.delete(key: _legacyPublicKeyKey);
    await secureStorage.delete(key: _legacyPrivateKeyKey);
    return true;
  }

  /// The public key the server has for [userId], or null if they have none.
  Future<String?> _fetchServerPublicKey(String userId) async {
    try {
      final response = await dio.get('/chat/keys/$userId');
      return response.data['identityPublicKey'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Forgets the key pair kept on this device for [userId].
  Future<void> deleteIdentityKeyPair(String userId) async {
    await secureStorage.delete(key: _publicKeyKey(userId));
    await secureStorage.delete(key: _privateKeyKey(userId));
    if (_loaded?.userId == userId) _loaded = null;
  }

  /// Whether the pair kept here is the account's: the server lists its
  /// public key, or listed none and now does.
  ///
  /// False when the server lists another key: the account set up chat on
  /// another device since, and the pair kept here is no longer the one
  /// others encrypt to. It is never replaced from here without being asked
  /// ([createAndPublishKeyPair]), or two devices would keep replacing each
  /// other's key. True when the server cannot be asked: chat goes on with
  /// the keys it has.
  Future<bool> publishPublicKeyIfMissing(String userId) async {
    final pubKeyBase64 = await secureStorage.read(key: _publicKeyKey(userId));
    if (pubKeyBase64 == null) return true;

    final String? serverKey;
    try {
      serverKey = await _fetchServerPublicKey(userId);
    } catch (e) {
      AppLogger.error('Could not compare the chat key with the server', e);
      return true;
    }
    if (serverKey == pubKeyBase64) return true;
    if (serverKey != null) return false;
    return _uploadKey(pubKeyBase64);
  }

  /// Makes a new key pair for [userId] and publishes it in place of any key
  /// the server lists, then keeps it here. Nothing is kept unless the server
  /// took it. The server refuses (409) while a backup PIN protects the
  /// account: its keys are then replaced only with that PIN.
  Future<KeyPair> createAndPublishKeyPair(String userId) async {
    final keyPair = cryptoService.generateKeyPair();
    await dio.post(
      '/chat/keys',
      data: {'identityPublicKey': base64Encode(keyPair.publicKey)},
    );
    await saveIdentityKeyPair(userId, keyPair);
    return keyPair;
  }

  /// False only when the server answers that the account has other keys.
  Future<bool> _uploadKey(String pubKeyBase64) async {
    try {
      await dio.post('/chat/keys', data: {'identityPublicKey': pubKeyBase64});
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return false;
      // Anything else is tried again the next time chat is opened.
      AppLogger.error('Failed to upload public key', e);
    } catch (e) {
      AppLogger.error('Failed to upload public key', e);
    }
    return true;
  }
}
