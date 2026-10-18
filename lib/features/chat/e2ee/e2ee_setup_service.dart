import 'dart:convert';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/key_backup_vault.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';
import 'package:genie/features/chat/e2ee/password_key_lock.dart';

/// How [E2eeSetupService.initialize] ended. The UI turns this into a message.
enum E2eeSetupResult {
  ready,

  /// The account has a backup PIN (or its chats are locked with the account
  /// password) and none was given.
  cancelled,
  wrongPin,

  /// The account password typed to open the chats is not the account's.
  wrongPassword,
  rateLimited,
  failed,

  /// The account set up chat on another device since, without a backup PIN,
  /// so this device cannot have its keys. Chat works here again once the
  /// user asks for it ([E2eeSetupService.initialize] with `takeOver`).
  usedOnAnotherDevice,

  /// The account's chats are locked with a password that was reset since,
  /// and this device does not have the keys. A device that has them locks
  /// them with the new password when it signs in; or the user starts over
  /// here ([E2eeSetupService.initialize] with `takeOver`), giving up the
  /// earlier messages.
  lockedWithEarlierPassword,
}

/// Asks the user for what opens their chat keys: the backup PIN, or for an
/// account whose chats are locked with it, the account password. Returns
/// null if they cancel.
typedef PinPrompt = Future<String?> Function(BackupLock lock);

/// Makes end-to-end encryption ready on this device. Contains no UI.
///
/// Messages are always end-to-end encrypted. An account that signs in with
/// a password has its keys backed up under that password whenever it is
/// typed ([initialize] with `password`), so any device it signs in on gets
/// the chats back. An account that signs in only with Google may choose a
/// backup PIN instead; without either, the keys live on this device only and
/// a new device makes new ones (earlier messages cannot be read there).
class E2eeSetupService {
  final KeyService keyService;
  final BackupService backupService;
  final ChatBackupRepository backupRepository;

  late final KeyBackupVault _vault = KeyBackupVault(
    backupService: backupService,
    backupRepository: backupRepository,
  );

  late final PasswordKeyLock _passwordLock = PasswordKeyLock(
    keyService: keyService,
    backupRepository: backupRepository,
    vault: _vault,
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
  /// backup PIN or its password is reported as [E2eeSetupResult.cancelled].
  /// [takeOver] makes new keys when the account moved to another device.
  ///
  /// [password] is the account password, just typed to sign in or set: the
  /// keys are then restored with it, or locked with it (a PIN backup is
  /// switched over, asking the PIN one last time).
  Future<E2eeSetupResult> initialize(
    String userId, {
    PinPrompt? askPin,
    bool takeOver = false,
    String? password,
  }) {
    final result = _running.then(
      (_) => _initialize(
        userId,
        askPin: askPin,
        takeOver: takeOver,
        password: password,
      ),
    );
    _running = result;
    return result;
  }

  Future<E2eeSetupResult> _initialize(
    String userId, {
    required PinPrompt? askPin,
    required bool takeOver,
    required String? password,
  }) async {
    try {
      final hasKeys =
          await keyService.hasLocalKeyPair(userId) ||
          await keyService.adoptLegacyKeyPair(userId);
      final keysCurrent =
          hasKeys && await keyService.publishPublicKeyIfMissing(userId);
      if (keysCurrent && password == null) return E2eeSetupResult.ready;

      // No keys here, the server lists other keys for the account, or a
      // password to lock the keys with.
      final backup = await backupRepository.fetchBackup();
      if (password != null || backup?.lock == BackupLock.password) {
        final typed = password ?? await askPin?.call(BackupLock.password);
        if (typed == null) return E2eeSetupResult.cancelled;
        return await _withPassword(
          userId,
          typed,
          backup: backup,
          hasKeys: hasKeys,
          keysCurrent: keysCurrent,
          askPin: askPin,
          takeOver: takeOver,
        );
      }
      if (backup != null) return await _restoreIdentity(userId, backup, askPin);
      if (hasKeys && !takeOver) return E2eeSetupResult.usedOnAnotherDevice;

      await keyService.createAndPublishKeyPair(userId);
      return E2eeSetupResult.ready;
    } on BackupRateLimitedException {
      return E2eeSetupResult.rateLimited;
    } on WrongPinException {
      return E2eeSetupResult.wrongPin;
    } on WrongPasswordException {
      return E2eeSetupResult.wrongPassword;
    } catch (e, stackTrace) {
      AppLogger.error('E2EE setup failed', e, stackTrace);
      return E2eeSetupResult.failed;
    }
  }

  /// "Reset keys" for an account whose chats are locked with its
  /// [password]: new keys, locked with it. Earlier messages can no longer be
  /// read anywhere.
  Future<E2eeSetupResult> startOver(String userId, String password) {
    final result = _running.then((_) async {
      try {
        await _passwordLock.startOver(userId, password);
        return E2eeSetupResult.ready;
      } on WrongPasswordException {
        return E2eeSetupResult.wrongPassword;
      } on BackupRateLimitedException {
        return E2eeSetupResult.rateLimited;
      } catch (e, stackTrace) {
        AppLogger.error('Could not reset the chat keys', e, stackTrace);
        return E2eeSetupResult.failed;
      }
    });
    _running = result;
    return result;
  }

  /// With the account [password]: the keys here are locked with it, or
  /// restored with it, or (no device here can open them) replaced when the
  /// user asked for chat here ([takeOver]).
  Future<E2eeSetupResult> _withPassword(
    String userId,
    String password, {
    required StoredBackup? backup,
    required bool hasKeys,
    required bool keysCurrent,
    required PinPrompt? askPin,
    required bool takeOver,
  }) async {
    if (keysCurrent) {
      await _passwordLock.lockCurrentKeys(userId, password, backup);
      return E2eeSetupResult.ready;
    }

    if (backup == null) {
      // The keys live only on the device that made them.
      if (hasKeys && !takeOver) return E2eeSetupResult.usedOnAnotherDevice;
      await _passwordLock.startOver(userId, password);
      return E2eeSetupResult.ready;
    }

    if (backup.lock == BackupLock.pin) {
      final pin = await askPin?.call(BackupLock.pin);
      if (pin == null) return E2eeSetupResult.cancelled;
      await _passwordLock.switchFromPin(
        userId,
        pin: pin,
        password: password,
        backup: backup,
      );
      return E2eeSetupResult.ready;
    }

    try {
      await _passwordLock.restore(userId, password, backup);
      return E2eeSetupResult.ready;
    } on WrongPinException {
      // A typo, or the backup is locked with a password reset since. Only a
      // device that still has the keys can lock them again without losing
      // the history; the user decides whether to start over here instead.
      await _passwordLock.checkPassword(password);
      if (!takeOver) return E2eeSetupResult.lockedWithEarlierPassword;
      await _passwordLock.startOver(userId, password);
      return E2eeSetupResult.ready;
    }
  }

  /// The account has a backup PIN: unlock the server backup with it. A wrong
  /// PIN or a locked backup is reported by [_initialize].
  Future<E2eeSetupResult> _restoreIdentity(
    String userId,
    StoredBackup backup,
    PinPrompt? askPin,
  ) async {
    final pin = await askPin?.call(BackupLock.pin);
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
