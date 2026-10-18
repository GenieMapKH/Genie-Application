import 'dart:convert';

import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/key_backup_vault.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';

/// Keeps an account's chat keys locked with its password, so signing in on
/// any device brings the chats back with nothing more to type.
///
/// The password is only used while it is in hand (signing in, changing it)
/// and is never stored. Replacing a backup is proven with it
/// ([ChatBackupRepository.provePassword]), so a backup locked with the PIN
/// or with a password that was reset since can still be replaced.
class PasswordKeyLock {
  final KeyService keyService;
  final ChatBackupRepository backupRepository;
  final KeyBackupVault vault;

  PasswordKeyLock({
    required this.keyService,
    required this.backupRepository,
    required this.vault,
  });

  /// This device holds the account's current keys: makes sure [password]
  /// opens their [backup]. A missing backup is made; one locked with the PIN
  /// or an earlier password is replaced.
  Future<void> lockCurrentKeys(
    String userId,
    String password,
    StoredBackup? backup,
  ) async {
    if (backup != null &&
        backup.lock == BackupLock.password &&
        backup.legacyKey == null) {
      try {
        await vault.open(password, backup);
        return;
      } on WrongPinException {
        // Locked with an earlier password: it was reset since. Lock again.
      }
    }

    final keyPair = (await keyService.getIdentityKeyPair(userId))!;
    await vault.save(
      password,
      keyPair.secretKey.extractBytes(),
      ownerProof: backup == null ? null : await _proof(password),
      lock: BackupLock.password,
    );
  }

  /// Restores the account's keys on this device from [backup] with
  /// [password]. Throws [WrongPinException] when [password] does not open it.
  Future<void> restore(
    String userId,
    String password,
    StoredBackup backup,
  ) async {
    final opened = await vault.open(password, backup);
    await _keep(userId, opened.privateKey);
  }

  /// The backup PIN's last use: restores the keys from the PIN-locked
  /// [backup] with [pin], then locks them with [password] instead.
  Future<void> switchFromPin(
    String userId, {
    required String pin,
    required String password,
    required StoredBackup backup,
  }) async {
    final opened = await vault.open(pin, backup);
    await _keep(userId, opened.privateKey);
    await vault.save(
      password,
      opened.privateKey,
      ownerProof: await _proof(password),
      lock: BackupLock.password,
    );
  }

  /// New keys, locked with [password], in place of keys no device here can
  /// open. Earlier messages can no longer be read. Throws
  /// [WrongPasswordException] when [password] is not the account's.
  Future<void> startOver(String userId, String password) async {
    final proof = await _proof(password);
    final keyPair = keyService.cryptoService.generateKeyPair();
    await backupRepository.resetKeys(
      publicKey: base64Encode(keyPair.publicKey),
      backup: await vault.seal(
        password,
        keyPair.secretKey.extractBytes(),
        lock: BackupLock.password,
      ),
      ownerProof: proof,
    );
    // Kept only once the server took it.
    await keyService.saveIdentityKeyPair(userId, keyPair);
  }

  /// Throws [WrongPasswordException] when [password] is not the account's.
  Future<void> checkPassword(String password) =>
      backupRepository.provePassword(password);

  Future<BackupOwnerProof> _proof(String password) async =>
      BackupOwnerProof.password(await backupRepository.provePassword(password));

  Future<void> _keep(String userId, List<int> privateKey) async {
    await keyService.restoreIdentityKeyPair(
      userId,
      publicKey: base64Decode(await backupRepository.fetchPublicKey(userId)),
      secretKeyBytes: privateKey,
    );
  }
}
