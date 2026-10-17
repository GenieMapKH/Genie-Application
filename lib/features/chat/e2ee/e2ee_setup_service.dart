import 'dart:convert';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/key_backup_vault.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';

/// How [E2eeSetupService.initialize] ended. The UI turns this into a message.
enum E2eeSetupResult {
  ready,

  /// The account has a backup PIN and none was given.
  cancelled,
  wrongPin,
  rateLimited,
  failed,

  /// The account set up chat on another device since, without a backup PIN,
  /// so this device cannot have its keys. Chat works here again once the
  /// user asks for it ([E2eeSetupService.initialize] with `takeOver`).
  usedOnAnotherDevice,
}

/// Asks the user for their backup PIN. Returns null if they cancel.
typedef PinPrompt = Future<String?> Function();

/// Makes end-to-end encryption ready on this device. Contains no UI.
///
/// Messages are always end-to-end encrypted. The backup PIN is optional:
/// without one, the keys live on this device only, and a new device makes
/// new keys (earlier messages cannot be read there). With one, a new device
/// restores the keys from the PIN-protected backup, which is the only time
/// a PIN is asked for here.
class E2eeSetupService {
  final KeyService keyService;
  final BackupService backupService;
  final ChatBackupRepository backupRepository;

  late final KeyBackupVault _vault = KeyBackupVault(
    backupService: backupService,
    backupRepository: backupRepository,
  );

  /// The setup in progress. The quiet one at sign-in and one started by a
  /// chat screen run one after the other, or both could make keys.
  Future<void> _running = Future.value();

  E2eeSetupService({
    required this.keyService,
    required this.backupService,
    required this.backupRepository,
  });

  /// Without [askPin] nothing is asked: an account whose keys are behind a
  /// backup PIN is reported as [E2eeSetupResult.cancelled]. [takeOver] makes
  /// new keys when the account moved to another device.
  Future<E2eeSetupResult> initialize(
    String userId, {
    PinPrompt? askPin,
    bool takeOver = false,
  }) {
    final result = _running.then(
      (_) => _initialize(userId, askPin: askPin, takeOver: takeOver),
    );
    _running = result;
    return result;
  }

  Future<E2eeSetupResult> _initialize(
    String userId, {
    required PinPrompt? askPin,
    required bool takeOver,
  }) async {
    try {
      final hasKeys =
          await keyService.hasLocalKeyPair(userId) ||
          await keyService.adoptLegacyKeyPair(userId);
      if (hasKeys && await keyService.publishPublicKeyIfMissing(userId)) {
        return E2eeSetupResult.ready;
      }

      // No keys here, or the server lists other keys for the account.
      final backup = await backupRepository.fetchBackup();
      if (backup != null) return await _restoreIdentity(userId, backup, askPin);
      if (hasKeys && !takeOver) return E2eeSetupResult.usedOnAnotherDevice;

      await keyService.createAndPublishKeyPair(userId);
      return E2eeSetupResult.ready;
    } on BackupRateLimitedException {
      return E2eeSetupResult.rateLimited;
    } on WrongPinException {
      return E2eeSetupResult.wrongPin;
    } catch (e, stackTrace) {
      AppLogger.error('E2EE setup failed', e, stackTrace);
      return E2eeSetupResult.failed;
    }
  }

  /// The account has a backup PIN: unlock the server backup with it. A wrong
  /// PIN or a locked backup is reported by [_initialize].
  Future<E2eeSetupResult> _restoreIdentity(
    String userId,
    StoredBackup backup,
    PinPrompt? askPin,
  ) async {
    final pin = await askPin?.call();
    if (pin == null) return E2eeSetupResult.cancelled;

    final opened = await _vault.open(pin, backup);
    await keyService.restoreIdentityKeyPair(
      userId,
      publicKey: base64Decode(await backupRepository.fetchPublicKey(userId)),
      secretKeyBytes: opened.privateKey,
    );
    return E2eeSetupResult.ready;
  }
}
