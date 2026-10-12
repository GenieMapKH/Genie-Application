import 'package:dio/dio.dart';
import 'package:genie/core/errors/app_exceptions.dart';

/// The identity private key, encrypted on the device with a key made from the
/// user's PIN. [verifier] lets the server check the PIN without knowing it.
class EncryptedBackup {
  final String blob;
  final String salt;
  final String nonce;
  final String verifier;

  const EncryptedBackup({
    required this.blob,
    required this.salt,
    required this.nonce,
    required this.verifier,
  });
}

/// The encrypted key itself, as the server releases it.
class SealedKey {
  final String blob;
  final String nonce;

  const SealedKey({required this.blob, required this.nonce});
}

/// What the server tells a signed-in device before the PIN is proven.
class StoredBackup {
  final String salt;

  /// Only for a backup made before the server counted PIN tries: it is still
  /// handed out whole, and replaced the first time it is opened.
  final SealedKey? legacyKey;

  const StoredBackup({required this.salt, this.legacyKey});
}

/// Thrown while the server refuses backup requests: too many lookups, or the
/// backup is locked after too many wrong PINs.
class BackupRateLimitedException extends AppException {
  const BackupRateLimitedException()
    : super('Too many backup attempts', code: '429');
}

/// Thrown when the server rejects the PIN. The try has been counted.
class WrongPinException extends AppException {
  const WrongPinException() : super('Wrong PIN', code: '403');
}

/// API access for the E2EE key backup and public keys.
class ChatBackupRepository {
  final Dio dio;

  ChatBackupRepository({required this.dio});

  /// The stored backup, or null when the user has never created one.
  Future<StoredBackup?> fetchBackup() async {
    try {
      final response = await dio.get('/chat/backup');
      final data = response.data;
      final legacyBlob = data['backupBlob'] as String?;
      final legacyNonce = data['backupNonce'] as String?;
      return StoredBackup(
        salt: data['backupSalt'] as String,
        legacyKey: legacyBlob != null && legacyNonce != null
            ? SealedKey(blob: legacyBlob, nonce: legacyNonce)
            : null,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) return null;
      if (status == 429) throw const BackupRateLimitedException();
      rethrow;
    }
  }

  /// Asks the server for the encrypted key. Each wrong [verifier] is counted,
  /// and after several the backup locks for a while.
  Future<SealedKey> unlockBackup(String verifier) async {
    try {
      final response = await dio.post(
        '/chat/backup/unlock',
        data: {'backupVerifier': verifier},
      );
      return SealedKey(
        blob: response.data['backupBlob'] as String,
        nonce: response.data['backupNonce'] as String,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) throw const WrongPinException();
      if (status == 429) throw const BackupRateLimitedException();
      rethrow;
    }
  }

  Future<void> saveBackup(EncryptedBackup backup) async {
    await dio.post(
      '/chat/backup',
      data: {
        'backupBlob': backup.blob,
        'backupSalt': backup.salt,
        'backupNonce': backup.nonce,
        'backupVerifier': backup.verifier,
      },
    );
  }

  /// Base64 public key of [userId] as stored on the server.
  Future<String> fetchPublicKey(String userId) async {
    final response = await dio.get('/chat/keys/$userId');
    return response.data['identityPublicKey'] as String;
  }
}
