import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// What a PIN and a salt turn into. The two halves are independent: knowing
/// [verifier] does not help to find [encryptionKey].
class BackupKeys {
  /// Encrypts the private key. Never leaves the device.
  final SecretKey encryptionKey;

  /// Proves the PIN to the server, which counts wrong tries.
  final String verifier;

  const BackupKeys({required this.encryptionKey, required this.verifier});
}

/// The cryptography of the PIN-protected key backup. No network access.
class BackupService {
  static const _keyLength = 32;

  final Argon2id _argon2id = Argon2id(
    parallelism: 1,
    memory: 19456,
    iterations: 2,
    hashLength: _keyLength * 2,
  );

  /// How backups were keyed before the server counted PIN tries.
  final Argon2id _legacyArgon2id = Argon2id(
    parallelism: 1,
    memory: 19456,
    iterations: 2,
    hashLength: _keyLength,
  );

  final secretBox = AesGcm.with256bits();

  Future<BackupKeys> deriveKeys(String pin, String saltB64) async {
    final derived = await _argon2id.deriveKeyFromPassword(
      password: pin,
      nonce: base64Decode(saltB64),
    );
    final bytes = await derived.extractBytes();
    return BackupKeys(
      encryptionKey: SecretKey(bytes.sublist(0, _keyLength)),
      verifier: base64Encode(bytes.sublist(_keyLength)),
    );
  }

  /// Encrypts [privateKeyBytes] under [pin]: `blob`, `salt`, `nonce`, `verifier`.
  Future<Map<String, String>> createBackup(
    String pin,
    List<int> privateKeyBytes,
  ) async {
    final salt = base64Encode(SecretKeyData.random(length: 16).bytes);
    final keys = await deriveKeys(pin, salt);
    final nonce = secretBox.newNonce();

    final sealed = await secretBox.encrypt(
      privateKeyBytes,
      secretKey: keys.encryptionKey,
      nonce: nonce,
    );

    return {
      'blob': base64Encode(sealed.cipherText + sealed.mac.bytes),
      'salt': salt,
      'nonce': base64Encode(nonce),
      'verifier': keys.verifier,
    };
  }

  /// Decrypts a backup the server released for [keys]. Throws if it was altered.
  Future<List<int>> openBackup(
    BackupKeys keys,
    String nonceB64,
    String blobB64,
  ) => _decrypt(keys.encryptionKey, nonceB64, blobB64);

  /// Opens a backup made before the server counted PIN tries.
  /// Throws when the PIN is wrong.
  Future<List<int>> restoreLegacyBackup(
    String pin,
    String saltB64,
    String nonceB64,
    String blobB64,
  ) async {
    final secretKey = await _legacyArgon2id.deriveKeyFromPassword(
      password: pin,
      nonce: base64Decode(saltB64),
    );
    return _decrypt(secretKey, nonceB64, blobB64);
  }

  Future<List<int>> _decrypt(
    SecretKey secretKey,
    String nonceB64,
    String blobB64,
  ) {
    final blob = base64Decode(blobB64);
    // The AES-GCM MAC is the last 16 bytes.
    final macStart = blob.length - 16;
    return secretBox.decrypt(
      SecretBox(
        blob.sublist(0, macStart),
        nonce: base64Decode(nonceB64),
        mac: Mac(blob.sublist(macStart)),
      ),
      secretKey: secretKey,
    );
  }
}
