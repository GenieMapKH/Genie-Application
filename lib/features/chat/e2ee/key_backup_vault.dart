import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';

/// What a backup held, after the right PIN opened it.
///
/// [proof] is what the server accepts as proof of that PIN when the backup is
/// replaced (new PIN, or new keys). It is null when the server has nothing to
/// check it against: a backup from before PIN tries were counted that could
/// not be upgraded just now.
typedef OpenedBackup = ({List<int> privateKey, BackupOwnerProof? proof});

/// Saves and opens the PIN-protected copy of the identity key on the server.
/// The server only releases it for the right PIN and counts every wrong one.
class KeyBackupVault {
  final BackupService backupService;
  final ChatBackupRepository backupRepository;

  KeyBackupVault({required this.backupService, required this.backupRepository});

  /// Encrypts [privateKey] under [pin], ready to be uploaded.
  Future<EncryptedBackup> seal(String pin, List<int> privateKey) async {
    final created = await backupService.createBackup(pin, privateKey);
    return EncryptedBackup(
      blob: created['blob']!,
      salt: created['salt']!,
      nonce: created['nonce']!,
      verifier: created['verifier']!,
    );
  }

  /// Stores a backup of [privateKey] under [pin]. Replacing an existing
  /// backup needs [ownerProof]: the PIN it has now, or the account password.
  Future<EncryptedBackup> save(
    String pin,
    List<int> privateKey, {
    BackupOwnerProof? ownerProof,
  }) async {
    final backup = await seal(pin, privateKey);
    await backupRepository.saveBackup(backup, ownerProof: ownerProof);
    return backup;
  }

  /// The private key inside [backup]. Throws [WrongPinException] for a wrong
  /// PIN and [BackupRateLimitedException] while the backup is locked.
  Future<OpenedBackup> open(String pin, StoredBackup backup) async {
    final legacyKey = backup.legacyKey;
    if (legacyKey != null) return _openLegacy(pin, backup.salt, legacyKey);

    final keys = await backupService.deriveKeys(pin, backup.salt);
    final sealed = await backupRepository.unlockBackup(keys.verifier);
    final privateKey = await backupService.openBackup(
      keys,
      sealed.nonce,
      sealed.blob,
    );
    return (privateKey: privateKey, proof: BackupOwnerProof.pin(keys.verifier));
  }

  /// Opens a backup from before the server counted PIN tries, then saves it
  /// again in the protected form so the old copy is removed.
  Future<OpenedBackup> _openLegacy(
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
      final upgraded = await save(pin, privateKey);
      return (
        privateKey: privateKey,
        proof: BackupOwnerProof.pin(upgraded.verifier),
      );
    } catch (e) {
      // The key is restored either way; the upgrade is tried again next time.
      AppLogger.error('Could not upgrade the key backup', e);
      return (privateKey: privateKey, proof: null);
    }
  }
}
