import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/e2ee/backup/password_lock_migration.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';

import 'e2ee_fakes.dart';

void main() {
  const passwordBackup = StoredBackup(salt: 's', lock: BackupLock.password);

  late FakeKeyService keys;
  late FakeBackupRepository repository;
  late PasswordLockMigration migration;

  setUp(() {
    keys = FakeKeyService();
    repository = FakeBackupRepository()
      ..stored = passwordBackup
      ..opensWith = 'right-password';
    final backups = FakeBackupService();
    migration = PasswordLockMigration(
      userId: 'u1',
      keyService: keys,
      backupService: backups,
      backupRepository: repository,
      keyManager: E2eeKeyManager(
        keyService: keys,
        backupService: backups,
        backupRepository: repository,
      ),
    );
  });

  group('on a device that holds the keys', () {
    setUp(() => keys.hasLocal = true);

    test('the password is proven, then the PIN replaces it', () async {
      expect(await migration.unlock('right-password'), isA<PinAccepted>());
      expect(await migration.moveToPin('482915'), isA<PinAccepted>());

      expect(repository.passwordProofs, 1);
      expect(repository.saved.single.verifier, 'new-verifier');
      expect(repository.proofs, [
        {'passwordProofToken': 'password-proof'},
      ]);
      expect(repository.resetPublicKeys, isEmpty);
    });

    test('a wrong password is refused and nothing changes', () async {
      expect(await migration.unlock('typo'), isA<PinRejected>());
      expect(await migration.moveToPin('482915'), isA<PinCheckFailed>());

      expect(repository.saved, isEmpty);
    });
  });

  group('on a new device', () {
    test('the password opens the backup, then the PIN replaces it', () async {
      expect(await migration.unlock('right-password'), isA<PinAccepted>());
      expect(keys.savedKeyPairs, 1);

      expect(await migration.moveToPin('482915'), isA<PinAccepted>());
      expect(repository.proofs, [
        {'currentBackupVerifier': 'proof-of-right-password'},
      ]);
    });

    test('wrong passwords are counted, and the backup is looked up once', () async {
      repository.attemptsLeft = 3;

      final first = await migration.unlock('typo');
      await migration.unlock('another-typo');

      expect((first as PinRejected).attemptsLeft, 3);
      expect(repository.unlockTries, hasLength(2));
      expect(repository.fetches, 1);
      expect(keys.savedKeyPairs, 0);
    });

    test('a locked backup says so', () async {
      repository.unlockError = const BackupRateLimitedException(
        retryAfter: Duration(minutes: 15),
      );

      expect(await migration.unlock('typo'), isA<PinLockedOut>());
    });

    test('a password reset since can start over with new keys', () async {
      // The backup still opens only with the password from before.
      repository.opensWith = 'old-password';

      expect(await migration.unlock('right-password'), isA<PinRejected>());
      expect(await migration.startOver('right-password'), isA<PinAccepted>());
      expect(await migration.moveToPin('482915'), isA<PinAccepted>());

      expect(repository.resetPublicKeys, hasLength(1));
      expect(repository.proofs, [
        {'passwordProofToken': 'password-proof'},
      ]);
    });

    test('starting over still needs the current password', () async {
      expect(await migration.startOver('typo'), isA<PinRejected>());
      expect(repository.resetPublicKeys, isEmpty);
    });
  });
}
