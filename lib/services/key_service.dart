import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium_libs/sodium_libs.dart';
import 'crypto_service.dart';

class KeyService {
  final FlutterSecureStorage secureStorage;
  final CryptoService cryptoService;
  final Dio dio;

  KeyService({
    required this.cryptoService,
    required this.dio,
    this.secureStorage = const FlutterSecureStorage(),
  });

  static const _publicKeyKey = 'identity_public_key';
  static const _privateKeyKey = 'identity_private_key';

  /// Checks if the identity key pair exists locally
  Future<bool> hasLocalKeyPair() async {
    final pubKeyBase64 = await secureStorage.read(key: _publicKeyKey);
    final privKeyBase64 = await secureStorage.read(key: _privateKeyKey);
    return pubKeyBase64 != null && privKeyBase64 != null;
  }

  /// Returns the existing identity key pair, or null if it doesn't exist
  Future<KeyPair?> getIdentityKeyPair() async {
    final pubKeyBase64 = await secureStorage.read(key: _publicKeyKey);
    final privKeyBase64 = await secureStorage.read(key: _privateKeyKey);

    if (pubKeyBase64 != null && privKeyBase64 != null) {
      final pubKey = base64Decode(pubKeyBase64);
      final privKeyBytes = base64Decode(privKeyBase64);
      final privKey = SecureKey.fromList(cryptoService.sodium, privKeyBytes);
      return KeyPair(publicKey: pubKey, secretKey: privKey);
    }
    return null;
  }

  /// Generates a new identity key pair and saves it securely
  Future<KeyPair> generateAndSaveIdentityKeyPair() async {
    final keyPair = cryptoService.generateKeyPair();
    await saveIdentityKeyPair(keyPair);
    return keyPair;
  }

  /// Saves a specific key pair to secure storage (e.g., after backup restore)
  Future<void> saveIdentityKeyPair(KeyPair keyPair) async {
    await secureStorage.write(
      key: _publicKeyKey,
      value: base64Encode(keyPair.publicKey),
    );
    await secureStorage.write(
      key: _privateKeyKey,
      value: base64Encode(keyPair.secretKey.extractBytes()),
    );
  }

  /// Compares the local public key with the server's, and uploads if missing or different
  Future<void> uploadPublicKeyIfNeeded(String userId) async {
    final pubKeyBase64 = await secureStorage.read(key: _publicKeyKey);
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
      await dio.post('/chat/keys', data: {
        'identityPublicKey': pubKeyBase64,
      });
    } catch (e) {
      print('Failed to upload public key: $e');
      // In production, we should handle this more gracefully, perhaps retry later.
    }
  }
}
