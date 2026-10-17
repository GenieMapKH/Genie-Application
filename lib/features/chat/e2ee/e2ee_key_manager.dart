import 'dart:convert';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/key_backup_vault.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';

enum SetUpPinResult {
  created,
  alreadySet,

  /// This device does not hold the keys the account uses now: chat has to
  /// be opened here first.
  keysNotReady,
  cancelled,
  rateLimited,
  fetchFailed,
  saveFailed,
}

enum TurnOffPinResult {
  turnedOff,
  noBackup,
  cancelled,
  wrongPin,
  rateLimited,
  fetchFailed,
  removeFailed,
}

enum ChangePinResult {
  changed,
  noBackup,
  rateLimited,
  fetchFailed,
  cancelled,
  wrongPin,
  saveFailed,
}

enum ResetKeysResult {
  reset,
  cancelled,
  wrongPin,
  rateLimited,
  fetchFailed,
  saveFailed,
}

/// How recovering from a forgotten PIN ended.
enum RecoverKeysResult {
  /// This device still had the keys: only the PIN changed, no history lost.
  keptKeys,

  /// New keys were made: earlier chat history can no longer be read.
  newKeys,
  cancelled,

  /// The server no longer accepts the password proof (it lasts a few minutes).
  proofRejected,
  failed,
}

/// Asks the user for a PIN. Returns null if they cancel.
typedef PinRequest = Future<String?> Function();

/// Why the current backup could not be opened.
enum _Refusal { cancelled, wrongPin, rateLimited, fetchFailed }

class _KeyAccessRefused implements Exception {
  final _Refusal reason;

  const _KeyAccessRefused(this.reason);
}

/// Account-level key maintenance from the security screen. No UI: PINs come
/// from the [PinRequest] callbacks and the outcome is returned as an enum.
///
/// The backup PIN is optional ([setUpBackupPin], [turnOffBackupPin]). Once
/// there is one, every operation that replaces what it protects starts with
/// proof that the owner is asking: the current PIN, or for someone who
/// forgot it, the account password ([recoverWithPassword]). Without that,
/// anyone holding the unlocked phone could put keys of their own on the
/// account and read its chats from then on.
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

  /// Protects the keys this device holds with a new backup PIN, so a new
  /// device can restore them. Only for an account without a PIN yet.
  Future<SetUpPinResult> setUpBackupPin(
    String userId, {
    required PinRequest askNewPin,
  }) async {
    try {
      if (await backupRepository.fetchBackup() != null) {
        return SetUpPinResult.alreadySet;
      }
    } on BackupRateLimitedException {
      return SetUpPinResult.rateLimited;
    } catch (e) {
      AppLogger.error('Could not fetch backup', e);
      return SetUpPinResult.fetchFailed;
    }
    // Backing up a pair the account no longer uses would restore nothing.
    if (!await holdsCurrentKeys(userId)) return SetUpPinResult.keysNotReady;

    final pin = await askNewPin();
    if (pin == null) return SetUpPinResult.cancelled;

    try {
      final keyPair = (await keyService.getIdentityKeyPair(userId))!;
      await _vault.save(pin, keyPair.secretKey.extractBytes());
      return SetUpPinResult.created;
    } catch (e) {
      AppLogger.error('Could not save the first backup', e);
      return SetUpPinResult.saveFailed;
    }
  }

  /// Removes the backup, after the current PIN proves the owner is asking.
  /// Chat stays end-to-end encrypted; a new device then makes new keys.
  Future<TurnOffPinResult> turnOffBackupPin({
    required PinRequest askCurrentPin,
  }) async {
    final OpenedBackup? current;
    try {
      current = await _openCurrentBackup(askCurrentPin);
    } on _KeyAccessRefused catch (refused) {
      return switch (refused.reason) {
        _Refusal.cancelled => TurnOffPinResult.cancelled,
        _Refusal.wrongPin => TurnOffPinResult.wrongPin,
        _Refusal.rateLimited => TurnOffPinResult.rateLimited,
        _Refusal.fetchFailed => TurnOffPinResult.fetchFailed,
      };
    }
    if (current == null) return TurnOffPinResult.noBackup;

    try {
      await backupRepository.removeBackup(ownerProof: current.proof);
      return TurnOffPinResult.turnedOff;
    } on WrongPinException {
      return TurnOffPinResult.wrongPin;
    } on BackupRateLimitedException {
      return TurnOffPinResult.rateLimited;
    } catch (e) {
      AppLogger.error('Could not remove the backup', e);
      return TurnOffPinResult.removeFailed;
    }
  }

  /// Re-encrypts the existing private key under a new PIN.
  Future<ChangePinResult> changeBackupPin({
    required PinRequest askCurrentPin,
    required PinRequest askNewPin,
  }) async {
    final OpenedBackup? current;
    try {
      current = await _openCurrentBackup(askCurrentPin);
    } on _KeyAccessRefused catch (refused) {
      return switch (refused.reason) {
        _Refusal.cancelled => ChangePinResult.cancelled,
        _Refusal.wrongPin => ChangePinResult.wrongPin,
        _Refusal.rateLimited => ChangePinResult.rateLimited,
        _Refusal.fetchFailed => ChangePinResult.fetchFailed,
      };
    }
    if (current == null) return ChangePinResult.noBackup;

    final newPin = await askNewPin();
    if (newPin == null) return ChangePinResult.cancelled;

    try {
      await _vault.save(newPin, current.privateKey, ownerProof: current.proof);
      return ChangePinResult.changed;
    } catch (e) {
      AppLogger.error('Could not save new backup', e);
      return ChangePinResult.saveFailed;
    }
  }

  /// Replaces the identity key. Old chat history can no longer be decrypted.
  /// The server swaps the public key and the backup together, and nothing
  /// changes on this device unless it did.
  Future<ResetKeysResult> resetKeys(
    String userId, {
    required PinRequest askCurrentPin,
    required PinRequest askNewPin,
  }) async {
    final OpenedBackup? current;
    try {
      // Null when no PIN protects the account yet: nothing to prove.
      current = await _openCurrentBackup(askCurrentPin);
    } on _KeyAccessRefused catch (refused) {
      return switch (refused.reason) {
        _Refusal.cancelled => ResetKeysResult.cancelled,
        _Refusal.wrongPin => ResetKeysResult.wrongPin,
        _Refusal.rateLimited => ResetKeysResult.rateLimited,
        _Refusal.fetchFailed => ResetKeysResult.fetchFailed,
      };
    }

    if (current == null) return _resetKeysWithoutPin(userId);

    final newPin = await askNewPin();
    if (newPin == null) return ResetKeysResult.cancelled;

    try {
      final keyPair = keyService.cryptoService.generateKeyPair();
      await backupRepository.resetKeys(
        publicKey: base64Encode(keyPair.publicKey),
        backup: await _vault.seal(newPin, keyPair.secretKey.extractBytes()),
        ownerProof: current.proof,
      );
      await keyService.saveIdentityKeyPair(userId, keyPair);
      return ResetKeysResult.reset;
    } on WrongPinException {
      return ResetKeysResult.wrongPin;
    } on BackupRateLimitedException {
      return ResetKeysResult.rateLimited;
    } catch (e) {
      AppLogger.error('Could not reset keys', e);
      return ResetKeysResult.saveFailed;
    }
  }

  /// No PIN protects the account: new keys, still without one.
  Future<ResetKeysResult> _resetKeysWithoutPin(String userId) async {
    try {
      await keyService.createAndPublishKeyPair(userId);
      return ResetKeysResult.reset;
    } catch (e) {
      AppLogger.error('Could not reset keys', e);
      return ResetKeysResult.saveFailed;
    }
  }

  /// Whether this device still holds the key pair the account uses now. If
  /// it does, a forgotten PIN can be replaced without losing any history.
  Future<bool> holdsCurrentKeys(String userId) async {
    try {
      final keyPair = await keyService.getIdentityKeyPair(userId);
      if (keyPair == null) return false;
      // Not the case after the keys were reset on another device.
      final serverKey = await backupRepository.fetchPublicKey(userId);
      return serverKey == base64Encode(keyPair.publicKey);
    } catch (e) {
      AppLogger.error('Could not compare the keys with the server', e);
      return false;
    }
  }

  /// The way back in for someone who forgot the PIN: [passwordProof] shows
  /// they typed their account password (`AccountRepository.requestPasswordProof`).
  ///
  /// If this device still holds the account's keys, they are kept and only
  /// backed up again under the new PIN. Otherwise the keys cannot be had
  /// without the old PIN, so new ones are made and old history is lost.
  Future<RecoverKeysResult> recoverWithPassword(
    String userId, {
    required String passwordProof,
    required PinRequest askNewPin,
  }) async {
    final keepsKeys = await holdsCurrentKeys(userId);
    final newPin = await askNewPin();
    if (newPin == null) return RecoverKeysResult.cancelled;

    final ownerProof = BackupOwnerProof.password(passwordProof);
    try {
      if (keepsKeys) {
        final keyPair = (await keyService.getIdentityKeyPair(userId))!;
        await _vault.save(
          newPin,
          keyPair.secretKey.extractBytes(),
          ownerProof: ownerProof,
        );
        return RecoverKeysResult.keptKeys;
      }

      final keyPair = keyService.cryptoService.generateKeyPair();
      await backupRepository.resetKeys(
        publicKey: base64Encode(keyPair.publicKey),
        backup: await _vault.seal(newPin, keyPair.secretKey.extractBytes()),
        ownerProof: ownerProof,
      );
      await keyService.saveIdentityKeyPair(userId, keyPair);
      return RecoverKeysResult.newKeys;
    } on WrongPinException {
      // No PIN was sent: it is the password proof the server refused.
      return RecoverKeysResult.proofRejected;
    } catch (e) {
      AppLogger.error('Could not recover the chat keys', e);
      return RecoverKeysResult.failed;
    }
  }

  /// For someone who forgot the PIN and would rather have none: the
  /// password proof removes the backup. A device without the account's keys
  /// gets new ones, so chat works here at once.
  Future<RecoverKeysResult> turnOffWithPassword(
    String userId, {
    required String passwordProof,
  }) async {
    final keepsKeys = await holdsCurrentKeys(userId);
    try {
      await backupRepository.removeBackup(
        ownerProof: BackupOwnerProof.password(passwordProof),
      );
      if (keepsKeys) return RecoverKeysResult.keptKeys;
      await keyService.createAndPublishKeyPair(userId);
      return RecoverKeysResult.newKeys;
    } on WrongPinException {
      return RecoverKeysResult.proofRejected;
    } catch (e) {
      AppLogger.error('Could not turn the PIN off', e);
      return RecoverKeysResult.failed;
    }
  }

  /// Opens the account's backup with the PIN from [askCurrentPin]: the server
  /// checks it and counts a wrong one. Returns null when there is no backup.
  Future<OpenedBackup?> _openCurrentBackup(PinRequest askCurrentPin) async {
    final StoredBackup? backup;
    try {
      backup = await backupRepository.fetchBackup();
    } on BackupRateLimitedException {
      throw const _KeyAccessRefused(_Refusal.rateLimited);
    } catch (e) {
      AppLogger.error('Could not fetch backup', e);
      throw const _KeyAccessRefused(_Refusal.fetchFailed);
    }
    if (backup == null) return null;

    final currentPin = await askCurrentPin();
    if (currentPin == null) throw const _KeyAccessRefused(_Refusal.cancelled);

    try {
      return await _vault.open(currentPin, backup);
    } on WrongPinException {
      throw const _KeyAccessRefused(_Refusal.wrongPin);
    } on BackupRateLimitedException {
      throw const _KeyAccessRefused(_Refusal.rateLimited);
    } catch (e) {
      AppLogger.error('Backup unlock failed', e);
      throw const _KeyAccessRefused(_Refusal.fetchFailed);
    }
  }
}
