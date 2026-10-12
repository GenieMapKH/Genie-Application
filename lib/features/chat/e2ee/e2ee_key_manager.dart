import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/key_backup_vault.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';

enum ChangePinResult {
  changed,
  noBackup,
  rateLimited,
  fetchFailed,
  cancelled,
  wrongPin,
  saveFailed,
}

enum ResetKeysResult { reset, cancelled, saveFailed }

/// Asks the user for a PIN. Returns null if they cancel.
typedef PinRequest = Future<String?> Function();

/// Account-level key maintenance from the profile screen. No UI: PINs come
/// from the [PinRequest] callbacks and the outcome is returned as an enum.
class E2eeKeyManager {
  final KeyService keyService;
  final BackupService backupService;
  final ChatBackupRepository backupRepository;

  late final KeyBackupVault _vault = KeyBackupVault(
    backupService: backupService,
    backupRepository: backupRepository,
  );

  E2eeKeyManager({
    required this.keyService,
    required this.backupService,
    required this.backupRepository,
  });

  /// Re-encrypts the existing private key under a new PIN.
  Future<ChangePinResult> changeBackupPin({
    required PinRequest askCurrentPin,
    required PinRequest askNewPin,
  }) async {
    final StoredBackup? backup;
    try {
      backup = await backupRepository.fetchBackup();
    } on BackupRateLimitedException {
      return ChangePinResult.rateLimited;
    } catch (e) {
      AppLogger.error('Could not fetch backup', e);
      return ChangePinResult.fetchFailed;
    }
    if (backup == null) return ChangePinResult.noBackup;

    final currentPin = await askCurrentPin();
    if (currentPin == null) return ChangePinResult.cancelled;

    final List<int> privateKey;
    try {
      privateKey = await _vault.open(currentPin, backup);
    } on WrongPinException {
      return ChangePinResult.wrongPin;
    } on BackupRateLimitedException {
      return ChangePinResult.rateLimited;
    } catch (e) {
      AppLogger.error('Backup unlock failed', e);
      return ChangePinResult.fetchFailed;
    }

    final newPin = await askNewPin();
    if (newPin == null) return ChangePinResult.cancelled;

    try {
      await _vault.save(newPin, privateKey);
      return ChangePinResult.changed;
    } catch (e) {
      AppLogger.error('Could not save new backup', e);
      return ChangePinResult.saveFailed;
    }
  }

  /// Replaces the identity key. Old chat history can no longer be decrypted.
  /// Nothing changes locally unless the new backup reached the server.
  Future<ResetKeysResult> resetKeys(
    String userId, {
    required PinRequest askNewPin,
  }) async {
    final newPin = await askNewPin();
    if (newPin == null) return ResetKeysResult.cancelled;

    try {
      final keyPair = keyService.cryptoService.generateKeyPair();
      await _vault.save(newPin, keyPair.secretKey.extractBytes());
      await keyService.saveIdentityKeyPair(userId, keyPair);
      await keyService.uploadPublicKeyIfNeeded(userId);
      return ResetKeysResult.reset;
    } catch (e) {
      AppLogger.error('Could not reset keys', e);
      return ResetKeysResult.saveFailed;
    }
  }
}
