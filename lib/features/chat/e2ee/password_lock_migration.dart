import 'dart:convert';

import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/e2ee/key_backup_vault.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';
import 'package:genie/features/chat/e2ee/pin_check.dart';

/// Moves chats still locked with the account password, as they were for a
/// short while, to the chat PIN. One per screen: [unlock] with the password
/// first, then [moveToPin]. No UI.
class PasswordLockMigration {
  final String userId;
  final KeyService keyService;
  final ChatBackupRepository backupRepository;
  final E2eeKeyManager keyManager;
  final KeyBackupVault _vault;

  /// Fetched once: every lookup counts against a small limit.
  StoredBackup? _backup;

  /// What lets [moveToPin] replace the password-locked backup.
  BackupOwnerProof? _proof;

  /// Set by [startOver]: new keys instead of the ones nobody can open.
  bool _newKeys = false;

  PasswordLockMigration({
    required this.userId,
    required this.keyService,
    required BackupService backupService,
    required this.backupRepository,
    required this.keyManager,
  }) : _vault = KeyBackupVault(
         backupService: backupService,
         backupRepository: backupRepository,
       );

  /// Checks [password]. A device without the account's keys gets them from
  /// the backup it opens; one with them proves the password to the server,
  /// which also works after the password was reset since.
  Future<PinCheckResult> unlock(String password) {
    return checkPin(() async {
      if (await keyManager.holdsCurrentKeys(userId)) {
        _proof = BackupOwnerProof.password(await _provePassword(password));
        return;
      }
      final backup = _backup ??= await backupRepository.fetchBackup();
      if (backup == null) throw StateError('The backup is gone');
      final opened = await _vault.open(password, backup);
      await keyService.restoreIdentityKeyPair(
        userId,
        publicKey: base64Decode(await backupRepository.fetchPublicKey(userId)),
        secretKeyBytes: opened.privateKey,
      );
      _proof = opened.proof;
    });
  }

  /// For a backup locked with a password that was reset since, which no
  /// device here can open: the current [password] lets new keys replace it.
  /// Earlier messages can no longer be read.
  Future<PinCheckResult> startOver(String password) {
    return checkPin(() async {
      _proof = BackupOwnerProof.password(await _provePassword(password));
      _newKeys = true;
    });
  }

  /// Protects the keys with [pin] in place of the password. Only after
  /// [unlock] or [startOver] accepted the password.
  Future<PinCheckResult> moveToPin(String pin) {
    return checkPin(() async {
      final proof = _proof;
      if (proof == null) throw StateError('Unlock with the password first');
      if (_newKeys) return keyManager.replaceKeys(userId, pin, proof);
      final keyPair = (await keyService.getIdentityKeyPair(userId))!;
      await _vault.save(
        pin,
        keyPair.secretKey.extractBytes(),
        ownerProof: proof,
      );
    });
  }

  /// A wrong password counts like a wrong PIN.
  Future<String> _provePassword(String password) async {
    try {
      return await backupRepository.provePassword(password);
    } on WrongPasswordException {
      throw const WrongPinException();
    }
  }
}
