import 'dart:convert';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/data/chat_backup_repository.dart';
import 'package:tilomnov/features/chat/e2ee/backup/backup_service.dart';
import 'package:tilomnov/features/chat/e2ee/backup/key_backup_vault.dart';
import 'package:tilomnov/features/chat/e2ee/keys/key_service.dart';

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

enum RecoverPinResult {
  /// A new PIN protects the keys this device holds: nothing was lost.
  recovered,

  /// A new PIN protects new keys: earlier messages can no longer be read.
  startedOver,
  cancelled,
  wrongPassword,
  rateLimited,
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
/// Every account has a chat PIN. Every operation that replaces what it
/// protects starts with proof that the owner is asking: the current PIN, or
/// for someone who forgot it, the account password ([recoverWithPassword]).
/// Without that, anyone holding the unlocked phone could put keys of their
/// own on the account and read its chats from then on.
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

    final newPin = await askNewPin();
    if (newPin == null) return ResetKeysResult.cancelled;

    try {
      await replaceKeys(userId, newPin, current?.proof);
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

  /// A forgotten PIN: the account [password] proves the owner is asking,
  /// then a new PIN protects the keys this device holds, or new keys when
  /// it does not hold the account's (earlier messages are then lost).
  Future<RecoverPinResult> recoverWithPassword(
    String userId, {
    required String password,
    required PinRequest askNewPin,
  }) async {
    final BackupOwnerProof proof;
    try {
      proof = BackupOwnerProof.password(
        await backupRepository.provePassword(password),
      );
    } on WrongPasswordException {
      return RecoverPinResult.wrongPassword;
    } on BackupRateLimitedException {
      return RecoverPinResult.rateLimited;
    } catch (e) {
      AppLogger.error('Could not confirm the password', e);
      return RecoverPinResult.failed;
    }

    final keepsKeys = await holdsCurrentKeys(userId);
    final newPin = await askNewPin();
    if (newPin == null) return RecoverPinResult.cancelled;

    try {
      if (!keepsKeys) {
        await replaceKeys(userId, newPin, proof);
        return RecoverPinResult.startedOver;
      }
      final keyPair = (await keyService.getIdentityKeyPair(userId))!;
      await _vault.save(
        newPin,
        keyPair.secretKey.extractBytes(),
        ownerProof: proof,
      );
      return RecoverPinResult.recovered;
    } on BackupRateLimitedException {
      return RecoverPinResult.rateLimited;
    } catch (e) {
      AppLogger.error('Could not save the new PIN', e);
      return RecoverPinResult.failed;
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

  /// New keys, protected by [pin], in place of the account's. [proof] shows
  /// the owner may replace the backup there is (null when there is none).
  /// Earlier messages can no longer be read.
  Future<void> replaceKeys(
    String userId,
    String pin,
    BackupOwnerProof? proof,
  ) async {
    final keyPair = keyService.cryptoService.generateKeyPair();
    await backupRepository.resetKeys(
      publicKey: base64Encode(keyPair.publicKey),
      backup: await _vault.seal(pin, keyPair.secretKey.extractBytes()),
      ownerProof: proof,
    );
    // Kept only once the server took it.
    await keyService.saveIdentityKeyPair(userId, keyPair);
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
