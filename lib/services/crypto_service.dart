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
