import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class BackupService {
  final Argon2id argon2id = Argon2id(
    parallelism: 1,
    memory: 19456,
    iterations: 2,
    hashLength: 32,
  );

  final secretBox = AesGcm.with256bits();

  Future<Map<String, String>> createBackup(
    String pin,
    List<int> privateKeyBytes,
  ) async {
    // Generate a random salt for Argon2
    final salt = SecretKeyData.random(length: 16).bytes;

    // Derive the encryption key from the PIN
    final secretKey = await argon2id.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );

    // Generate a random nonce for SecretBox
    final nonce = secretBox.newNonce();

    // Encrypt the private key
    final secretBoxState = await secretBox.encrypt(
      privateKeyBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'blob': base64Encode(
        secretBoxState.cipherText + secretBoxState.mac.bytes,
      ),
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
    };
  }

  Future<List<int>> restoreBackup(
    String pin,
    String saltB64,
    String nonceB64,
    String blobB64,
  ) async {
    final salt = base64Decode(saltB64);
    final nonce = base64Decode(nonceB64);
    final blob = base64Decode(blobB64);

    // AES-GCM MAC is the last 16 bytes
    final cipherText = blob.sublist(0, blob.length - 16);
    final mac = Mac(blob.sublist(blob.length - 16));

    // Re-derive the key from the PIN
    final secretKey = await argon2id.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );

    // Decrypt the private key
    final secretBoxState = SecretBox(cipherText, nonce: nonce, mac: mac);

    final privateKeyBytes = await secretBox.decrypt(
      secretBoxState,
      secretKey: secretKey,
    );

    return privateKeyBytes;
  }
}
