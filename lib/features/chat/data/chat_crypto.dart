import 'dart:convert';
import 'dart:typed_data';
import 'package:sodium_libs/sodium_libs.dart';

class CryptoService {
  final Sodium sodium;

  CryptoService(this.sodium);

  static Future<CryptoService> init() async {
    final sodium = await SodiumInit.init();
    return CryptoService(sodium);
  }

  /// Encrypts a file with a fresh one-time key. The key and nonce are
  /// returned so they can be sent inside the encrypted message.
  ({Uint8List cipher, String key, String nonce}) encryptFile(Uint8List bytes) {
    final key = sodium.crypto.secretBox.keygen();
    final nonce = sodium.randombytes.buf(sodium.crypto.secretBox.nonceBytes);
    try {
      return (
        cipher: sodium.crypto.secretBox.easy(
          message: bytes,
          nonce: nonce,
          key: key,
        ),
        key: base64Encode(key.extractBytes()),
        nonce: base64Encode(nonce),
      );
    } finally {
      key.dispose();
    }
  }

  /// Opens a file encrypted by [encryptFile]. Throws if the key is wrong or
  /// a single byte was changed.
  Uint8List decryptFile(
    Uint8List cipher,
    String keyBase64,
    String nonceBase64,
  ) {
    final key = sodium.secureCopy(base64Decode(keyBase64));
    try {
      return sodium.crypto.secretBox.openEasy(
        cipherText: cipher,
        nonce: base64Decode(nonceBase64),
        key: key,
      );
    } finally {
      key.dispose();
    }
  }
}
