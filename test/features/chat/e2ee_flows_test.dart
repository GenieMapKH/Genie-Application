import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';

import 'e2ee_fakes.dart';

void main() {
  const existingBackup = StoredBackup(salt: 's');
  const passwordBackup = StoredBackup(salt: 's', lock: BackupLock.password);
  const legacyBackup = StoredBackup(
    salt: 's',
    legacyKey: SealedKey(blob: 'old-blob', nonce: 'old-nonce'),
  );

  group('E2eeKeyManager.changeBackupPin', () {
    late FakeKeyService keys;
    late FakeBackupRepository repository;
    late E2eeKeyManager manager;

    setUp(() {
      keys = FakeKeyService();
      repository = FakeBackupRepository()..stored = existingBackup;
      manager = E2eeKeyManager(
        keyService: keys,
        backupService: FakeBackupService(),
        backupRepository: repository,
      );
    });

    Future<ChangePinResult> change({
      String? current = '111111',
      String? next = '222222',
    }) {
      return manager.changeBackupPin(
        askCurrentPin: () async => current,
        askNewPin: () async => next,
      );
    }

    test('re-encrypts the key under the new PIN', () async {
      expect(await change(), ChangePinResult.changed);
      expect(repository.unlockTries, ['proof-of-111111']);
      expect(repository.saved.single.blob, 'new-blob');
      expect(repository.saved.single.verifier, 'new-verifier');
    });

    test(
      'proves the current PIN to the server when it replaces the backup',
      () async {
        await change();

        expect(repository.proofs, [
          {'currentBackupVerifier': 'proof-of-111111'},
        ]);
      },
    );

    test('reports a missing backup', () async {
      repository.stored = null;

      expect(await change(), ChangePinResult.noBackup);
    });

    test('reports rate limiting', () async {
      repository.fetchError = const BackupRateLimitedException();

      expect(await change(), ChangePinResult.rateLimited);
    });

    test('rejects a wrong current PIN without touching the backup', () async {
      repository.unlockError = const WrongPinException();

      expect(await change(), ChangePinResult.wrongPin);
      expect(repository.saved, isEmpty);
    });

    test('reports a backup locked after too many wrong PINs', () async {
      repository.unlockError = const BackupRateLimitedException();

      expect(await change(), ChangePinResult.rateLimited);
      expect(repository.saved, isEmpty);
    });

    test('stops quietly when the user cancels', () async {
      expect(await change(current: null), ChangePinResult.cancelled);
      expect(await change(next: null), ChangePinResult.cancelled);
      expect(repository.saved, isEmpty);
    });

    test('reports a failed upload', () async {
      repository.saveError = Exception('offline');

      expect(await change(), ChangePinResult.saveFailed);
    });
  });

  group('E2eeKeyManager.resetKeys', () {
    late FakeKeyService keys;
    late FakeBackupRepository repository;
    late E2eeKeyManager manager;

    setUp(() {
      keys = FakeKeyService();
      repository = FakeBackupRepository()..stored = existingBackup;
      manager = E2eeKeyManager(
        keyService: keys,
        backupService: FakeBackupService(),
        backupRepository: repository,
      );
    });

    Future<ResetKeysResult> reset({
      String? current = '111111',
      String? next = '222222',
    }) {
      return manager.resetKeys(
        'user-1',
        askCurrentPin: () async => current,
        askNewPin: () async => next,
      );
    }

    test('asks for the current PIN and proves it to the server', () async {
      expect(await reset(), ResetKeysResult.reset);

      expect(repository.unlockTries, ['proof-of-111111']);
      expect(repository.proofs, [
        {'currentBackupVerifier': 'proof-of-111111'},
      ]);
      expect(repository.resetPublicKeys, ['CQ==']);
      expect(repository.saved.single.verifier, 'new-verifier');
      expect(keys.savedKeyPairs, 1);
    });

    test('a wrong current PIN resets nothing', () async {
      repository.unlockError = const WrongPinException();

      expect(await reset(), ResetKeysResult.wrongPin);
      expect(repository.resetPublicKeys, isEmpty);
      expect(keys.savedKeyPairs, 0);
    });

    test('a locked backup cannot be reset around', () async {
      repository.unlockError = const BackupRateLimitedException();

      expect(await reset(), ResetKeysResult.rateLimited);
      expect(repository.resetPublicKeys, isEmpty);
    });

    test(
      'keeps the old local keys when the server refuses the reset',
      () async {
        repository.resetError = const WrongPinException();
        expect(await reset(), ResetKeysResult.wrongPin);

        repository.resetError = Exception('500');
        expect(await reset(), ResetKeysResult.saveFailed);

        expect(keys.savedKeyPairs, 0);
      },
    );

    test('cancelling either PIN prompt changes nothing', () async {
      expect(await reset(current: null), ResetKeysResult.cancelled);
      expect(await reset(next: null), ResetKeysResult.cancelled);

      expect(repository.resetPublicKeys, isEmpty);
      expect(keys.savedKeyPairs, 0);
    });

    test('new keys always get a PIN, with nothing to prove when there was '
        'no backup', () async {
      repository.stored = null;

      final result = await manager.resetKeys(
        'user-1',
        askCurrentPin: () async => fail('there is no current PIN'),
        askNewPin: () async => '482915',
      );

      expect(result, ResetKeysResult.reset);
      expect(repository.resetPublicKeys, hasLength(1));
      expect(repository.proofs, [null]);
    });

    test(
      'an older backup is checked on the device, then upgraded and proven',
      () async {
        repository.stored = legacyBackup;

        expect(await reset(), ResetKeysResult.reset);
        // First the upgrade (nothing to prove yet), then the reset with its proof.
        expect(repository.proofs, [
          null,
          {'currentBackupVerifier': 'new-verifier'},
        ]);
      },
    );

    test('reports a backup that cannot be reached', () async {
      repository.fetchError = Exception('offline');

      expect(await reset(), ResetKeysResult.fetchFailed);
    });
  });

  group('E2eeKeyManager.recoverWithPassword', () {
    late FakeKeyService keys;
    late FakeBackupRepository repository;
    late E2eeKeyManager manager;

    setUp(() {
      keys = FakeKeyService();
      repository = FakeBackupRepository()..stored = existingBackup;
      manager = E2eeKeyManager(
        keyService: keys,
        backupService: FakeBackupService(),
        backupRepository: repository,
      );
    });

    Future<RecoverPinResult> recover({
      String password = 'right-password',
      String? newPin = '482915',
    }) {
      return manager.recoverWithPassword(
        'user-1',
        password: password,
        askNewPin: () async => newPin,
      );
    }

    test('a device with the keys keeps them under the new PIN', () async {
      keys.hasLocal = true;

      expect(await recover(), RecoverPinResult.recovered);

      expect(repository.resetPublicKeys, isEmpty);
      expect(repository.saved.single.verifier, 'new-verifier');
      expect(repository.proofs, [
        {'passwordProofToken': 'password-proof'},
      ]);
    });

    test('a device without them starts over with new keys', () async {
      expect(await recover(), RecoverPinResult.startedOver);

      expect(repository.resetPublicKeys, hasLength(1));
      expect(repository.proofs, [
        {'passwordProofToken': 'password-proof'},
      ]);
      expect(keys.savedKeyPairs, 1);
    });

    test('a wrong password asks for no PIN and changes nothing', () async {
      final result = await manager.recoverWithPassword(
        'user-1',
        password: 'typo',
        askNewPin: () async => fail('the password was wrong'),
      );

      expect(result, RecoverPinResult.wrongPassword);
      expect(repository.saved, isEmpty);
    });

    test('closing the new PIN prompt changes nothing', () async {
      keys.hasLocal = true;

      expect(await recover(newPin: null), RecoverPinResult.cancelled);
      expect(repository.saved, isEmpty);
    });
  });

  group('E2eeSetupService.initialize', () {
    late FakeKeyService keys;
    late FakeBackupService backups;
    late FakeBackupRepository repository;
    late E2eeSetupService service;

    setUp(() {
      keys = FakeKeyService();
      backups = FakeBackupService();
      repository = FakeBackupRepository();
      service = E2eeSetupService(
        keyService: keys,
        backupService: backups,
        backupRepository: repository,
      );
    });

    test('with keys already on the device it asks for nothing', () async {
      keys.hasLocal = true;

      final result = await service.initialize('u1', askPin: neverAsked);

      expect(result, E2eeSetupResult.ready);
      expect(keys.publicKeyUploads, 1);
      // No lookup either: those are limited.
      expect(repository.fetches, 0);
    });

    test('keys from before per-account storage are reused', () async {
      keys.hasLegacy = true;

      final result = await service.initialize('u1', askPin: neverAsked);

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 0);
    });

    test('a brand-new account gets keys quietly, so others can message it, '
        'and still has to create its PIN', () async {
      expect(await service.initialize('u1'), E2eeSetupResult.ready);
      expect(keys.publishedNewPairs, 1);
      expect(await service.pinStatus(), ChatPinStatus.notSet);
    });

    test('opening a chat without a PIN asks for one to be created', () async {
      final result = await service.initialize('u1', askPin: neverAsked);

      expect(result, E2eeSetupResult.pinNotSet);
      expect(keys.publishedNewPairs, 0);
    });

    test('keys another device replaced, without a PIN, wait for the PIN to '
        'be created', () async {
      keys.hasLocal = true;
      keys.serverAcceptsLocalKey = false;

      expect(await service.initialize('u1'), E2eeSetupResult.pinNotSet);
      expect(keys.publishedNewPairs, 0);
    });

    test('chats still locked with the password are moved first', () async {
      repository.stored = passwordBackup;

      final result = await service.initialize('u1', askPin: neverAsked);

      expect(result, E2eeSetupResult.lockedWithPassword);
      expect(repository.unlockTries, isEmpty);
    });

    test('without a prompt, keys behind the PIN wait for the chat screen', () async {
      repository.stored = existingBackup;

      expect(await service.initialize('u1'), E2eeSetupResult.cancelled);
      expect(repository.unlockTries, isEmpty);
      expect(keys.savedKeyPairs, 0);
      expect(keys.publishedNewPairs, 0);
    });

    test('setups running at once make keys only once', () async {
      keys.publishGate = Completer<void>();

      final quiet = service.initialize('u1');
      final fromChat = service.initialize('u1', askPin: neverAsked);
      await Future<void>.delayed(Duration.zero);
      keys.publishGate!.complete();

      expect(await quiet, E2eeSetupResult.ready);
      expect(await fromChat, E2eeSetupResult.ready);
      expect(keys.publishedNewPairs, 1);
    });

    test('nothing is kept when the new key cannot be published', () async {
      keys.publishError = Exception('offline');

      expect(await service.initialize('u1'), E2eeSetupResult.failed);
      expect(keys.hasLocal, isFalse);
    });

    test('keys reset on another device are restored with the PIN', () async {
      keys.hasLocal = true;
      keys.serverAcceptsLocalKey = false;
      repository.stored = existingBackup;

      final result = await service.initialize(
        'u1',
        askPin: typing(['123456']),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 1);
      expect(keys.publishedNewPairs, 0);
    });

    test('the server decides whether the PIN is right', () async {
      repository.stored = existingBackup;

      await service.initialize('u1', askPin: typing(['123456']));

      expect(repository.unlockTries, ['proof-of-123456']);
    });

    test('a wrong PIN is answered with the tries left while the prompt '
        'stays open, and the right one then restores', () async {
      repository.stored = existingBackup;
      repository.opensWith = '123456';
      repository.attemptsLeft = 4;
      final seen = <PinCheckResult>[];

      final result = await service.initialize(
        'u1',
        askPin: typing(['000000', '123456'], seen: seen),
      );

      expect(result, E2eeSetupResult.ready);
      expect(seen.first, isA<PinRejected>());
      expect((seen.first as PinRejected).attemptsLeft, 4);
      expect(seen.last, isA<PinAccepted>());
      expect(keys.savedKeyPairs, 1);
      // The backup was looked up once, not once per try.
      expect(repository.fetches, 1);
    });

    test('giving up after a wrong PIN restores nothing', () async {
      repository.stored = existingBackup;
      repository.opensWith = '123456';

      final result = await service.initialize(
        'u1',
        askPin: typing(['000000']),
      );

      expect(result, E2eeSetupResult.cancelled);
      expect(keys.savedKeyPairs, 0);
      expect(keys.publicKeyUploads, 0);
    });

    test('a lock after too many wrong PINs says how long it lasts', () async {
      repository.stored = existingBackup;
      repository.unlockError = const BackupRateLimitedException(
        retryAfter: Duration(minutes: 15),
      );
      final seen = <PinCheckResult>[];

      final result = await service.initialize(
        'u1',
        askPin: typing(['000000'], seen: seen),
      );

      expect(result, E2eeSetupResult.rateLimited);
      expect(
        (seen.single as PinLockedOut).retryAfter,
        const Duration(minutes: 15),
      );
      expect(keys.savedKeyPairs, 0);
    });

    test('an older backup is opened once and saved in the new form', () async {
      repository.stored = legacyBackup;

      final result = await service.initialize(
        'u1',
        askPin: typing(['123456']),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 1);
      expect(repository.unlockTries, isEmpty);
      expect(repository.saved.single.verifier, 'new-verifier');
    });

    test('an older backup still restores if the upgrade fails', () async {
      repository.stored = legacyBackup;
      repository.saveError = Exception('offline');

      final result = await service.initialize(
        'u1',
        askPin: typing(['123456']),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 1);
    });

    test('a wrong PIN on an older backup restores nothing', () async {
      repository.stored = legacyBackup;
      backups.pinIsCorrect = false;
      final seen = <PinCheckResult>[];

      final result = await service.initialize(
        'u1',
        askPin: typing(['000000'], seen: seen),
      );

      expect(result, E2eeSetupResult.cancelled);
      expect(seen.single, isA<PinRejected>());
      expect(repository.saved, isEmpty);
    });

    test('a backup that does not match the public key is refused', () async {
      repository.stored = existingBackup;
      keys.restoredKeyMatches = false;
      final seen = <PinCheckResult>[];

      await service.initialize('u1', askPin: typing(['123456'], seen: seen));

      expect(seen.single, isA<PinCheckFailed>());
      expect(keys.savedKeyPairs, 0);
      expect(keys.publicKeyUploads, 0);
    });

    test('closing the prompt does nothing', () async {
      repository.stored = existingBackup;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => false,
      );

      expect(result, E2eeSetupResult.cancelled);
      expect(keys.savedKeyPairs, 0);
    });

    test('maps server rate limiting and other failures', () async {
      repository.fetchError = const BackupRateLimitedException();
      expect(
        await service.initialize('u1', askPin: neverAsked),
        E2eeSetupResult.rateLimited,
      );

      repository.fetchError = Exception('boom');
      expect(
        await service.initialize('u1', askPin: neverAsked),
        E2eeSetupResult.failed,
      );
    });
  });

  group('E2eeSetupService.createPin', () {
    late FakeKeyService keys;
    late FakeBackupRepository repository;
    late E2eeSetupService service;

    setUp(() {
      keys = FakeKeyService();
      repository = FakeBackupRepository();
      service = E2eeSetupService(
        keyService: keys,
        backupService: FakeBackupService(),
        backupRepository: repository,
      );
    });

    test('protects the keys this device holds, with nothing to prove', () async {
      keys.hasLocal = true;

      expect(await service.createPin('u1', '482915'), CreatePinResult.created);

      expect(repository.saved.single.verifier, 'new-verifier');
      expect(repository.proofs, [null]);
      expect(repository.resetPublicKeys, isEmpty);
    });

    test('without the keys here, makes new ones under the PIN', () async {
      expect(await service.createPin('u1', '482915'), CreatePinResult.created);

      expect(repository.resetPublicKeys, hasLength(1));
      expect(keys.savedKeyPairs, 1);
    });

    test('keys the account no longer uses are replaced, not backed up', () async {
      keys.hasLocal = true;
      keys.serverAcceptsLocalKey = false;

      expect(await service.createPin('u1', '482915'), CreatePinResult.created);

      expect(repository.resetPublicKeys, hasLength(1));
    });

    test('a PIN set on another device meanwhile is not overwritten', () async {
      keys.hasLocal = true;
      // The server wants the PIN of the backup that exists now.
      repository.saveError = const WrongPinException();

      expect(
        await service.createPin('u1', '482915'),
        CreatePinResult.alreadySet,
      );
    });

    test('nothing is kept on the device when the server refuses', () async {
      repository.resetError = Exception('offline');

      expect(await service.createPin('u1', '482915'), CreatePinResult.failed);
      expect(keys.savedKeyPairs, 0);
    });
  });

  group('E2eeSetupService.pinStatus', () {
    late FakeBackupRepository repository;
    late E2eeSetupService service;

    setUp(() {
      repository = FakeBackupRepository();
      service = E2eeSetupService(
        keyService: FakeKeyService(),
        backupService: FakeBackupService(),
        backupRepository: repository,
      );
    });

    test('tells a PIN, no PIN and a password lock apart', () async {
      expect(await service.pinStatus(), ChatPinStatus.notSet);

      repository.stored = existingBackup;
      expect(await service.pinStatus(), ChatPinStatus.set);

      repository.stored = passwordBackup;
      expect(await service.pinStatus(), ChatPinStatus.lockedWithPassword);
    });

    test('a server that cannot be asked decides nothing', () async {
      repository.fetchError = const BackupRateLimitedException();
      expect(await service.pinStatus(), ChatPinStatus.unknown);

      repository.fetchError = Exception('offline');
      expect(await service.pinStatus(), ChatPinStatus.unknown);
    });
  });
}
