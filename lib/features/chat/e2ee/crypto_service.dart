import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sodium_libs/sodium_libs.dart';

class CryptoService {
  final Sodium sodium;

  CryptoService(this.sodium);

  static Future<CryptoService> init() async {
    final sodium = await SodiumInit.init();
    return CryptoService(sodium);
  }

  /// Generates a new X25519 key pair for identity
  KeyPair generateKeyPair() {
    return sodium.crypto.box.keyPair();
  }

  /// Whether [secretKey] belongs to [publicKey]: only the matching secret
  /// key can open a box sealed for the public key.
  bool isKeyPair(Uint8List publicKey, SecureKey secretKey) {
    final probe = sodium.randombytes.buf(16);
    try {
      final sealed = sodium.crypto.box.seal(
        message: probe,
        publicKey: publicKey,
      );
      final opened = sodium.crypto.box.sealOpen(
        cipherText: sealed,
        publicKey: publicKey,
        secretKey: secretKey,
      );
      return listEquals(opened, probe);
    } on SodiumException {
      return false;
    }
  }

  /// A hash both people in a conversation can compute from their two public
  /// keys. It only matches on both devices if neither key was swapped.
  Uint8List fingerprint(Uint8List publicKeyA, Uint8List publicKeyB) {
    // Same order on both sides, whoever computes it.
    final ordered = _compare(publicKeyA, publicKeyB) <= 0
        ? [...publicKeyA, ...publicKeyB]
        : [...publicKeyB, ...publicKeyA];
    return sodium.crypto.genericHash(
      message: Uint8List.fromList(ordered),
      outLen: 32,
    );
  }

  int _compare(Uint8List a, Uint8List b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a[i] - b[i];
    }
    return a.length - b.length;
  }

  /// Encrypts a message using the recipient's public key and the sender's private key
  Map<String, String> encryptMessage(
    String plaintext,
    Uint8List recipientPublicKey,
    SecureKey senderPrivateKey,
  ) {
    final messageBytes = utf8.encode(plaintext);
    final nonce = sodium.randombytes.buf(sodium.crypto.box.nonceBytes);

    final ciphertext = sodium.crypto.box.easy(
      message: Uint8List.fromList(messageBytes),
      nonce: nonce,
      publicKey: recipientPublicKey,
      secretKey: senderPrivateKey,
    );

    return {
      'ciphertext': base64Encode(ciphertext),
      'nonce': base64Encode(nonce),
    };
  }

  /// Decrypts a message using the sender's public key and the recipient's private key
  String decryptMessage(
    String ciphertextBase64,
    String nonceBase64,
    Uint8List senderPublicKey,
    SecureKey recipientPrivateKey,
  ) {
    final ciphertext = base64Decode(ciphertextBase64);
    final nonce = base64Decode(nonceBase64);

    final decryptedBytes = sodium.crypto.box.openEasy(
      cipherText: ciphertext,
      nonce: nonce,
      publicKey: senderPublicKey,
      secretKey: recipientPrivateKey,
    );

    return utf8.decode(decryptedBytes);
  }
}
