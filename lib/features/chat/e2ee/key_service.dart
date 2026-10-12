import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium_libs/sodium_libs.dart';
import 'package:genie/core/logging/app_logger.dart';
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

  /// Compares the local public key with the server's, and uploads if missing or different
  Future<void> uploadPublicKeyIfNeeded(String userId) async {
    final pubKeyBase64 = await secureStorage.read(key: _publicKeyKey(userId));
    if (pubKeyBase64 == null) return;

    try {
      final response = await dio.get('/chat/keys/$userId');
      final serverPubKey = response.data['identityPublicKey'];

      if (serverPubKey != pubKeyBase64) {
        await _uploadKey(pubKeyBase64);
      }
    } catch (e) {
      // If fetching fails (e.g. 404 Not Found), try to upload it
      await _uploadKey(pubKeyBase64);
    }
  }

  Future<void> _uploadKey(String pubKeyBase64) async {
    try {
      await dio.post('/chat/keys', data: {'identityPublicKey': pubKeyBase64});
    } catch (e) {
      AppLogger.error('Failed to upload public key', e);
      // In production, we should handle this more gracefully, perhaps retry later.
    }
  }
}
