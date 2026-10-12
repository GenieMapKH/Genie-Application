import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';

/// Saves and opens the PIN-protected copy of the identity key on the server.
/// The server only releases it for the right PIN and counts every wrong one.
class KeyBackupVault {
  final BackupService backupService;
  final ChatBackupRepository backupRepository;

  KeyBackupVault({required this.backupService, required this.backupRepository});

  Future<void> save(String pin, List<int> privateKey) async {
    final created = await backupService.createBackup(pin, privateKey);
    await backupRepository.saveBackup(
      EncryptedBackup(
        blob: created['blob']!,
        salt: created['salt']!,
        nonce: created['nonce']!,
        verifier: created['verifier']!,
      ),
    );
  }

  /// The private key inside [backup]. Throws [WrongPinException] for a wrong
  /// PIN and [BackupRateLimitedException] while the backup is locked.
  Future<List<int>> open(String pin, StoredBackup backup) async {
    final legacyKey = backup.legacyKey;
    if (legacyKey != null) return _openLegacy(pin, backup.salt, legacyKey);

    final keys = await backupService.deriveKeys(pin, backup.salt);
    final sealed = await backupRepository.unlockBackup(keys.verifier);
    return backupService.openBackup(keys, sealed.nonce, sealed.blob);
  }

  /// Opens a backup from before the server counted PIN tries, then saves it
  /// again in the protected form so the old copy is removed.
  Future<List<int>> _openLegacy(
    String pin,
    String salt,
    SealedKey legacyKey,
  ) async {
    final List<int> privateKey;
    try {
      privateKey = await backupService.restoreLegacyBackup(
        pin,
        salt,
        legacyKey.nonce,
        legacyKey.blob,
      );
    } catch (e) {
      // A wrong PIN fails the AES-GCM authentication check.
      AppLogger.error('Backup restore failed', e);
      throw const WrongPinException();
    }

    try {
      await save(pin, privateKey);
    } catch (e) {
      // The key is restored either way; the upgrade is tried again next time.
      AppLogger.error('Could not upgrade the key backup', e);
    }
    return privateKey;
  }
}
