import 'dart:convert';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/key_backup_vault.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';

/// How [E2eeSetupService.initialize] ended. The UI turns this into a message.
enum E2eeSetupResult { ready, cancelled, wrongPin, rateLimited, failed }

/// Asks the user for their backup PIN. Returns null if they cancel.
typedef PinPrompt = Future<String?> Function({required bool isNewPin});

/// Makes end-to-end encryption ready on this device: finds or creates the
/// user's identity key and restores or creates its PIN-protected backup.
/// Contains no UI: the PIN comes from the [PinPrompt].
class E2eeSetupService {
  final KeyService keyService;
  final BackupService backupService;
  final ChatBackupRepository backupRepository;

  late final KeyBackupVault _vault = KeyBackupVault(
    backupService: backupService,
    backupRepository: backupRepository,
  );

  E2eeSetupService({
    required this.keyService,
    required this.backupService,
    required this.backupRepository,
  });

  Future<E2eeSetupResult> initialize(
    String userId, {
    required PinPrompt askPin,
  }) async {
    try {
      if (await keyService.hasLocalKeyPair(userId) ||
          await keyService.adoptLegacyKeyPair(userId)) {
        if (await keyService.uploadPublicKeyIfNeeded(userId)) {
          return E2eeSetupResult.ready;
        }
        // The keys were reset on another device. The pair kept here no longer
        // belongs to the account: drop it and restore the new one below.
        await keyService.deleteIdentityKeyPair(userId);
      }

      final backup = await backupRepository.fetchBackup();
      return backup == null
          ? await _createIdentity(userId, askPin)
          : await _restoreIdentity(userId, backup, askPin);
    } on BackupRateLimitedException {
      return E2eeSetupResult.rateLimited;
    } on WrongPinException {
      return E2eeSetupResult.wrongPin;
    } catch (e, stackTrace) {
      AppLogger.error('E2EE setup failed', e, stackTrace);
      return E2eeSetupResult.failed;
    }
  }

  /// First time on any device: create keys and protect them with a new PIN.
  Future<E2eeSetupResult> _createIdentity(
    String userId,
    PinPrompt askPin,
  ) async {
    final keyPair = await keyService.generateAndSaveIdentityKeyPair(userId);

    final pin = await askPin(isNewPin: true);
    if (pin != null) {
      await _vault.save(pin, keyPair.secretKey.extractBytes());
    }
    return _finish(userId);
  }

  /// New device for an existing account: unlock the server backup with the PIN.
  /// A wrong PIN or a locked backup is reported by [initialize].
  Future<E2eeSetupResult> _restoreIdentity(
    String userId,
    StoredBackup backup,
    PinPrompt askPin,
  ) async {
    final pin = await askPin(isNewPin: false);
    if (pin == null) return E2eeSetupResult.cancelled;

    final opened = await _vault.open(pin, backup);
    await keyService.restoreIdentityKeyPair(
      userId,
      publicKey: base64Decode(await backupRepository.fetchPublicKey(userId)),
      secretKeyBytes: opened.privateKey,
    );
    return _finish(userId);
  }

  Future<E2eeSetupResult> _finish(String userId) async {
    await keyService.uploadPublicKeyIfNeeded(userId);
    return E2eeSetupResult.ready;
  }
}
