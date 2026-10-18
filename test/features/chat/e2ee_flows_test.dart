import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show SecretKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/e2ee/backup_service.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';
import 'package:sodium_libs/sodium_libs.dart';

class _FakeSecureKey extends Fake implements SecureKey {
  @override
  Uint8List extractBytes() => Uint8List.fromList([1, 2, 3]);
}

KeyPair _fakeKeyPair() =>
    KeyPair(publicKey: Uint8List.fromList([9]), secretKey: _FakeSecureKey());

class _FakeCryptoService extends Fake implements CryptoService {
  @override
  KeyPair generateKeyPair() => _fakeKeyPair();
}

class _FakeKeyService extends Fake implements KeyService {
  bool hasLocal = false;
  bool hasLegacy = false;
  bool restoredKeyMatches = true;
  int savedKeyPairs = 0;
  int publicKeyUploads = 0;
  int deletedKeyPairs = 0;

  /// New pairs made and published in place of the account's key.
  int publishedNewPairs = 0;
  Object? publishError;

  /// Holds a new pair back until completed, to see setups overlap.
  Completer<void>? publishGate;

  /// False once the account's keys were replaced on another device.
  bool serverAcceptsLocalKey = true;

  _FakeKeyService();

  @override
  final CryptoService cryptoService = _FakeCryptoService();

  @override
  Future<bool> hasLocalKeyPair(String userId) async => hasLocal;

  @override
  Future<KeyPair?> getIdentityKeyPair(String userId) async =>
      hasLocal ? _fakeKeyPair() : null;

  @override
  Future<bool> adoptLegacyKeyPair(String userId) async => hasLegacy;

  @override
  Future<KeyPair> generateAndSaveIdentityKeyPair(String userId) async {
    savedKeyPairs++;
    return _fakeKeyPair();
  }

  @override
  Future<void> saveIdentityKeyPair(String userId, KeyPair keyPair) async =>
      savedKeyPairs++;

  @override
  Future<void> restoreIdentityKeyPair(
    String userId, {
    required Uint8List publicKey,
    required List<int> secretKeyBytes,
  }) async {
    if (!restoredKeyMatches) throw StateError('key mismatch');
    savedKeyPairs++;
  }

  @override
  Future<bool> publishPublicKeyIfMissing(String userId) async {
    publicKeyUploads++;
    return serverAcceptsLocalKey;
  }

  @override
  Future<KeyPair> createAndPublishKeyPair(String userId) async {
    await publishGate?.future;
    if (publishError != null) throw publishError!;
    publishedNewPairs++;
    hasLocal = true;
    serverAcceptsLocalKey = true;
    return _fakeKeyPair();
  }

  @override
  Future<void> deleteIdentityKeyPair(String userId) async {
    deletedKeyPairs++;
    // What is restored next is the account's current pair.
    serverAcceptsLocalKey = true;
  }
}

class _FakeBackupService extends Fake implements BackupService {
  bool pinIsCorrect = true;

  @override
  Future<Map<String, String>> createBackup(
    String pin,
    List<int> privateKeyBytes,
  ) async => {
    'blob': 'new-blob',
    'salt': 'new-salt',
    'nonce': 'new-nonce',
    'verifier': 'new-verifier',
  };

  @override
  Future<BackupKeys> deriveKeys(String pin, String saltB64) async =>
      BackupKeys(encryptionKey: SecretKey([0]), verifier: 'proof-of-$pin');

  @override
  Future<List<int>> openBackup(
    BackupKeys keys,
    String nonceB64,
    String blobB64,
  ) async => [1, 2, 3];

  @override
  Future<List<int>> restoreLegacyBackup(
    String pin,
    String saltB64,
    String nonceB64,
    String blobB64,
  ) async {
    if (!pinIsCorrect) throw Exception('MAC check failed');
    return [1, 2, 3];
  }
}

class _FakeBackupRepository extends Fake implements ChatBackupRepository {
  StoredBackup? stored;
  Object? fetchError;
  Object? unlockError;
  Object? saveError;
  Object? resetError;
  Object? removeError;
  final List<String> unlockTries = [];

  /// The proof sent with each removal of the backup (turning the PIN off).
  final List<Map<String, String>?> removedWith = [];
  final List<EncryptedBackup> saved = [];

  /// What was sent with each save or reset to show the backup may be
  /// replaced: the current PIN's proof, or a password proof.
  final List<Map<String, String>?> proofs = [];

  /// The public key the server lists for the account.
  String serverPublicKey = 'CQ=='; // base64 of [9], the fake key pair
  final List<String> resetPublicKeys = [];

  /// When set, only this PIN or password opens [stored].
  String? opensWith;

  /// The account's password, as the sign-in server knows it.
  String accountPassword = 'right-password';
  int passwordProofs = 0;

  @override
  Future<StoredBackup?> fetchBackup() async {
    if (fetchError != null) throw fetchError!;
    return stored;
  }

  @override
  Future<SealedKey> unlockBackup(String verifier) async {
    unlockTries.add(verifier);
    if (unlockError != null) throw unlockError!;
    final secret = opensWith;
    if (secret != null && verifier != 'proof-of-$secret') {
      throw const WrongPinException();
    }
    return const SealedKey(blob: 'b', nonce: 'n');
  }

  @override
  Future<String> provePassword(String password) async {
    if (password != accountPassword) throw const WrongPasswordException();
    passwordProofs++;
    return 'password-proof';
  }

  @override
  Future<void> saveBackup(
    EncryptedBackup backup, {
    BackupOwnerProof? ownerProof,
  }) async {
    if (saveError != null) throw saveError!;
    saved.add(backup);
    proofs.add(ownerProof?.toJson());
  }

  @override
  Future<void> resetKeys({
    required String publicKey,
    required EncryptedBackup backup,
    BackupOwnerProof? ownerProof,
  }) async {
    if (resetError != null) throw resetError!;
    resetPublicKeys.add(publicKey);
    saved.add(backup);
    proofs.add(ownerProof?.toJson());
  }

  @override
  Future<void> removeBackup({required BackupOwnerProof? ownerProof}) async {
    if (removeError != null) throw removeError!;
    removedWith.add(ownerProof?.toJson());
    stored = null;
  }

  @override
  Future<String> fetchPublicKey(String userId) async => serverPublicKey;
}

void main() {
  const existingBackup = StoredBackup(salt: 's');
  const legacyBackup = StoredBackup(
    salt: 's',
    legacyKey: SealedKey(blob: 'old-blob', nonce: 'old-nonce'),
  );

  group('E2eeKeyManager.changeBackupPin', () {
    late _FakeKeyService keys;
    late _FakeBackupService backups;
    late _FakeBackupRepository repository;
    late E2eeKeyManager manager;

    setUp(() {
      keys = _FakeKeyService();
      backups = _FakeBackupService();
      repository = _FakeBackupRepository()..stored = existingBackup;
      manager = E2eeKeyManager(
        keyService: keys,
        backupService: backups,
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
    late _FakeKeyService keys;
    late _FakeBackupRepository repository;
    late E2eeKeyManager manager;

    setUp(() {
      keys = _FakeKeyService();
      repository = _FakeBackupRepository()..stored = existingBackup;
      manager = E2eeKeyManager(
        keyService: keys,
        backupService: _FakeBackupService(),
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

    test('an account without a PIN gets new keys, still without one', () async {
      repository.stored = null;

      final result = await manager.resetKeys(
        'user-1',
        askCurrentPin: () async => fail('there is no current PIN'),
        askNewPin: () async => fail('the PIN is optional'),
      );

      expect(result, ResetKeysResult.reset);
      expect(keys.publishedNewPairs, 1);
      expect(repository.saved, isEmpty);
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

  group('E2eeKeyManager: the optional backup PIN', () {
    late _FakeKeyService keys;
    late _FakeBackupRepository repository;
    late E2eeKeyManager manager;

    setUp(() {
      keys = _FakeKeyService()..hasLocal = true;
      repository = _FakeBackupRepository();
      manager = E2eeKeyManager(
        keyService: keys,
        backupService: _FakeBackupService(),
        backupRepository: repository,
      );
    });

    test('a PIN set up later backs up the keys this device has', () async {
      final result = await manager.setUpBackupPin(
        'user-1',
        askNewPin: () async => '482915',
      );

      expect(result, SetUpPinResult.created);
      // The first backup has nothing to replace, so nothing to prove.
      expect(repository.proofs, [null]);
      expect(repository.saved.single.verifier, 'new-verifier');
    });

    test('a second PIN is not set up over the first', () async {
      repository.stored = existingBackup;

      final result = await manager.setUpBackupPin(
        'user-1',
        askNewPin: () async => fail('there is a PIN already'),
      );

      expect(result, SetUpPinResult.alreadySet);
      expect(repository.saved, isEmpty);
    });

    test('keys the account no longer uses are not backed up', () async {
      repository.serverPublicKey = 'bmV3ZXI=';

      final result = await manager.setUpBackupPin(
        'user-1',
        askNewPin: () async => fail('nothing to protect'),
      );

      expect(result, SetUpPinResult.keysNotReady);
    });

    test('turning the PIN off needs the current PIN, proven', () async {
      repository.stored = existingBackup;

      final result = await manager.turnOffBackupPin(
        askCurrentPin: () async => '111111',
      );

      expect(result, TurnOffPinResult.turnedOff);
      expect(repository.removedWith, [
        {'currentBackupVerifier': 'proof-of-111111'},
      ]);
    });

    test('a wrong or missing PIN turns nothing off', () async {
      repository.stored = existingBackup;
      repository.unlockError = const WrongPinException();

      expect(
        await manager.turnOffBackupPin(askCurrentPin: () async => '000000'),
        TurnOffPinResult.wrongPin,
      );
      expect(
        await manager.turnOffBackupPin(askCurrentPin: () async => null),
        TurnOffPinResult.cancelled,
      );
      expect(repository.removedWith, isEmpty);
    });

    test('there is nothing to turn off without a PIN', () async {
      final result = await manager.turnOffBackupPin(
        askCurrentPin: () async => fail('there is no PIN'),
      );

      expect(result, TurnOffPinResult.noBackup);
    });
  });

  group('E2eeSetupService.initialize', () {
    late _FakeKeyService keys;
    late _FakeBackupService backups;
    late _FakeBackupRepository repository;
    late E2eeSetupService service;

    setUp(() {
      keys = _FakeKeyService();
      backups = _FakeBackupService();
      repository = _FakeBackupRepository();
      service = E2eeSetupService(
        keyService: keys,
        backupService: backups,
        backupRepository: repository,
      );
    });

    test('with keys already on the device it asks for nothing', () async {
      keys.hasLocal = true;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => fail('must not ask'),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.publicKeyUploads, 1);
      expect(repository.saved, isEmpty);
    });

    test('keys from before per-account storage are reused', () async {
      keys.hasLegacy = true;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => fail('must not ask'),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 0);
    });

    test('keys reset on another device are replaced from the backup', () async {
      keys.hasLocal = true;
      keys.serverAcceptsLocalKey = false;
      repository.stored = existingBackup;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => '123456',
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 1);
      expect(keys.publishedNewPairs, 0);
    });

    test('first use makes keys without asking for a PIN', () async {
      final result = await service.initialize(
        'u1',
        askPin: (_) async => fail('the PIN is optional'),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.publishedNewPairs, 1);
      expect(repository.saved, isEmpty);
    });

    test(
      'keys another device replaced are taken back only when asked',
      () async {
        keys.hasLocal = true;
        keys.serverAcceptsLocalKey = false;

        expect(
          await service.initialize('u1'),
          E2eeSetupResult.usedOnAnotherDevice,
        );
        expect(keys.publishedNewPairs, 0);

        expect(
          await service.initialize('u1', takeOver: true),
          E2eeSetupResult.ready,
        );
        expect(keys.publishedNewPairs, 1);
      },
    );

    test(
      'without a prompt, keys behind a PIN wait for the chat screen',
      () async {
        repository.stored = existingBackup;

        expect(await service.initialize('u1'), E2eeSetupResult.cancelled);
        expect(repository.unlockTries, isEmpty);
        expect(keys.savedKeyPairs, 0);
        expect(keys.publishedNewPairs, 0);
      },
    );

    test('setups running at once make keys only once', () async {
      keys.publishGate = Completer<void>();

      final quiet = service.initialize('u1');
      final fromChat = service.initialize(
        'u1',
        askPin: (_) async => fail('the PIN is optional'),
      );
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

    test('a new device restores the backup with the PIN', () async {
      repository.stored = existingBackup;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => '123456',
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 1);
    });

    test('the server decides whether the PIN is right', () async {
      repository.stored = existingBackup;

      await service.initialize('u1', askPin: (_) async => '123456');

      expect(repository.unlockTries, ['proof-of-123456']);
    });

    test('a backup locked after too many wrong PINs is reported', () async {
      repository.stored = existingBackup;
      repository.unlockError = const BackupRateLimitedException();

      final result = await service.initialize(
        'u1',
        askPin: (_) async => '000000',
      );

      expect(result, E2eeSetupResult.rateLimited);
      expect(keys.savedKeyPairs, 0);
    });

    test('an older backup is opened once and saved in the new form', () async {
      repository.stored = legacyBackup;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => '123456',
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
        askPin: (_) async => '123456',
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 1);
    });

    test('a wrong PIN on an older backup restores nothing', () async {
      repository.stored = legacyBackup;
      backups.pinIsCorrect = false;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => '000000',
      );

      expect(result, E2eeSetupResult.wrongPin);
      expect(repository.saved, isEmpty);
    });

    test('a wrong PIN restores nothing', () async {
      repository.stored = existingBackup;
      repository.unlockError = const WrongPinException();

      final result = await service.initialize(
        'u1',
        askPin: (_) async => '000000',
      );

      expect(result, E2eeSetupResult.wrongPin);
      expect(keys.savedKeyPairs, 0);
      expect(keys.publicKeyUploads, 0);
    });

    test('a backup that does not match the public key is refused', () async {
      repository.stored = existingBackup;
      keys.restoredKeyMatches = false;

      final result = await service.initialize(
        'u1',
        askPin: (_) async => '123456',
      );

      expect(result, E2eeSetupResult.failed);
      expect(keys.savedKeyPairs, 0);
      expect(keys.publicKeyUploads, 0);
    });

    test('cancelling the restore prompt does nothing', () async {
      repository.stored = existingBackup;

      final result = await service.initialize('u1', askPin: (_) async => null);

      expect(result, E2eeSetupResult.cancelled);
      expect(keys.savedKeyPairs, 0);
    });

    test('maps server rate limiting and other failures', () async {
      repository.fetchError = const BackupRateLimitedException();
      expect(
        await service.initialize('u1', askPin: (_) async => '1'),
        E2eeSetupResult.rateLimited,
      );

      repository.fetchError = Exception('boom');
      expect(
        await service.initialize('u1', askPin: (_) async => '1'),
        E2eeSetupResult.failed,
      );
    });
  });

  group('E2eeSetupService with the account password', () {
    late _FakeKeyService keys;
    late _FakeBackupRepository repository;
    late E2eeSetupService service;
    const passwordBackup = StoredBackup(salt: 's', lock: BackupLock.password);
    const pinBackup = StoredBackup(salt: 's');

    setUp(() {
      keys = _FakeKeyService();
      repository = _FakeBackupRepository();
      service = E2eeSetupService(
        keyService: keys,
        backupService: _FakeBackupService(),
        backupRepository: repository,
      );
    });

    Future<E2eeSetupResult> signIn({
      String password = 'right-password',
      PinPrompt? askPin,
      bool takeOver = false,
    }) => service.initialize(
      'u1',
      password: password,
      askPin: askPin ?? (_) async => fail('must not ask'),
      takeOver: takeOver,
    );

    group('on a device that has the keys', () {
      setUp(() => keys.hasLocal = true);

      test('a first sign-in locks them with the password', () async {
        expect(await signIn(), E2eeSetupResult.ready);

        expect(repository.saved.single.lock, BackupLock.password);
        expect(repository.proofs.single, isNull);
      });

      test(
        'a PIN backup is switched to the password, without the PIN',
        () async {
          repository.stored = pinBackup;
          repository.opensWith = '123456';

          expect(await signIn(), E2eeSetupResult.ready);

          expect(repository.saved.single.lock, BackupLock.password);
          expect(repository.proofs.single, {
            'passwordProofToken': 'password-proof',
          });
        },
      );

      test('nothing changes when the password already locks them', () async {
        repository.stored = passwordBackup;
        repository.opensWith = 'right-password';

        expect(await signIn(), E2eeSetupResult.ready);

        expect(repository.saved, isEmpty);
      });

      test('they are locked again after the password was reset', () async {
        repository.stored = passwordBackup;
        repository.opensWith = 'old-password';

        expect(await signIn(), E2eeSetupResult.ready);

        expect(repository.saved.single.lock, BackupLock.password);
        expect(repository.passwordProofs, 1);
      });
    });

    group('on a new device', () {
      test('the password brings the chats back, asking nothing', () async {
        repository.stored = passwordBackup;
        repository.opensWith = 'right-password';

        expect(await signIn(), E2eeSetupResult.ready);

        expect(keys.savedKeyPairs, 1);
        expect(repository.saved, isEmpty);
      });

      test('a PIN backup asks the PIN one last time, then uses the '
          'password', () async {
        repository.stored = pinBackup;
        repository.opensWith = '123456';
        final asked = <BackupLock>[];

        final result = await signIn(
          askPin: (lock) async {
            asked.add(lock);
            return '123456';
          },
        );

        expect(result, E2eeSetupResult.ready);
        expect(asked, [BackupLock.pin]);
        expect(keys.savedKeyPairs, 1);
        expect(repository.saved.single.lock, BackupLock.password);
      });

      test('skipping that PIN changes nothing', () async {
        repository.stored = pinBackup;

        final result = await signIn(askPin: (_) async => null);

        expect(result, E2eeSetupResult.cancelled);
        expect(repository.saved, isEmpty);
        expect(keys.savedKeyPairs, 0);
      });

      test('without any backup, new keys are made and locked', () async {
        expect(await signIn(), E2eeSetupResult.ready);

        expect(repository.resetPublicKeys, hasLength(1));
        expect(repository.saved.single.lock, BackupLock.password);
        expect(keys.savedKeyPairs, 1);
      });

      group('after the password was reset', () {
        setUp(() {
          repository.stored = passwordBackup;
          repository.opensWith = 'old-password';
        });

        test('nothing is replaced until the user asks for chat here', () async {
          expect(await signIn(), E2eeSetupResult.lockedWithEarlierPassword);

          expect(repository.resetPublicKeys, isEmpty);
          expect(keys.savedKeyPairs, 0);
        });

        test('asking for chat here makes new keys, locked with the new '
            'password', () async {
          expect(await signIn(takeOver: true), E2eeSetupResult.ready);

          expect(repository.resetPublicKeys, hasLength(1));
          expect(repository.saved.single.lock, BackupLock.password);
          expect(repository.proofs.single, {
            'passwordProofToken': 'password-proof',
          });
        });
      });
    });

    group('opening a chat on a new device', () {
      setUp(() {
        repository.stored = passwordBackup;
        repository.opensWith = 'right-password';
      });

      test('asks for the account password, not a PIN', () async {
        final asked = <BackupLock>[];

        final result = await service.initialize(
          'u1',
          askPin: (lock) async {
            asked.add(lock);
            return 'right-password';
          },
        );

        expect(result, E2eeSetupResult.ready);
        expect(asked, [BackupLock.password]);
        expect(keys.savedKeyPairs, 1);
      });

      test('a mistyped password is reported as such', () async {
        final result = await service.initialize(
          'u1',
          askPin: (_) async => 'typo',
        );

        expect(result, E2eeSetupResult.wrongPassword);
        expect(keys.savedKeyPairs, 0);
        expect(repository.resetPublicKeys, isEmpty);
      });
    });

    test('reset keys needs the right password', () async {
      keys.hasLocal = true;
      repository.stored = passwordBackup;

      expect(
        await service.startOver('u1', 'typo'),
        E2eeSetupResult.wrongPassword,
      );
      expect(repository.resetPublicKeys, isEmpty);

      expect(
        await service.startOver('u1', 'right-password'),
        E2eeSetupResult.ready,
      );
      expect(repository.resetPublicKeys, hasLength(1));
      expect(repository.saved.single.lock, BackupLock.password);
    });
  });
}
