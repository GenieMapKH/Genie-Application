import 'package:dio/dio.dart';
import 'package:genie/core/errors/app_exceptions.dart';

/// The identity private key, encrypted on the device with the user's PIN.
/// The server stores it but can never read it.
class EncryptedBackup {
  final String blob;
  final String salt;
  final String nonce;

  const EncryptedBackup({
    required this.blob,
    required this.salt,
    required this.nonce,
  });
}

/// Thrown when the server limits how often the backup can be downloaded.
class BackupRateLimitedException extends AppException {
  const BackupRateLimitedException()
    : super('Too many backup attempts', code: '429');
}

/// API access for the E2EE key backup and public keys.
class ChatBackupRepository {
  final Dio dio;

  ChatBackupRepository({required this.dio});

  /// The stored backup, or null when the user has never created one.
  Future<EncryptedBackup?> fetchBackup() async {
    try {
      final response = await dio.get('/chat/backup');
      final data = response.data;
      return EncryptedBackup(
        blob: data['backupBlob'],
        salt: data['backupSalt'],
        nonce: data['backupNonce'],
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) return null;
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
      },
    );
  }

  /// Base64 public key of [userId] as stored on the server.
  Future<String> fetchPublicKey(String userId) async {
    final response = await dio.get('/chat/keys/$userId');
    return response.data['identityPublicKey'] as String;
  }
}
