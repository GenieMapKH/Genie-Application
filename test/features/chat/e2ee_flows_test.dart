import 'dart:typed_data';

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

  _FakeKeyService();

  @override
  final CryptoService cryptoService = _FakeCryptoService();

  @override
  Future<bool> hasLocalKeyPair(String userId) async => hasLocal;

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
  Future<void> uploadPublicKeyIfNeeded(String userId) async =>
      publicKeyUploads++;
}

class _FakeBackupService extends Fake implements BackupService {
  bool pinIsCorrect = true;

  @override
  Future<Map<String, String>> createBackup(
    String pin,
    List<int> privateKeyBytes,
  ) async => {'blob': 'new-blob', 'salt': 'new-salt', 'nonce': 'new-nonce'};

  @override
  Future<List<int>> restoreBackup(
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
  EncryptedBackup? stored;
  Object? fetchError;
  Object? saveError;
  final List<EncryptedBackup> saved = [];

  @override
  Future<EncryptedBackup?> fetchBackup() async {
    if (fetchError != null) throw fetchError!;
    return stored;
  }

  @override
  Future<void> saveBackup(EncryptedBackup backup) async {
    if (saveError != null) throw saveError!;
    saved.add(backup);
  }

  @override
  Future<String> fetchPublicKey(String userId) async => 'CQ=='; // base64 of [9]
}

void main() {
  const existingBackup = EncryptedBackup(blob: 'b', salt: 's', nonce: 'n');

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
      expect(repository.saved.single.blob, 'new-blob');
    });

    test('reports a missing backup', () async {
      repository.stored = null;

      expect(await change(), ChangePinResult.noBackup);
    });

    test('reports rate limiting', () async {
      repository.fetchError = const BackupRateLimitedException();

      expect(await change(), ChangePinResult.rateLimited);
    });

    test('rejects a wrong current PIN without touching the backup', () async {
      backups.pinIsCorrect = false;

      expect(await change(), ChangePinResult.wrongPin);
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
    test('uploads the new backup, then saves the keys locally', () async {
      final keys = _FakeKeyService();
      final repository = _FakeBackupRepository();
      final manager = E2eeKeyManager(
        keyService: keys,
        backupService: _FakeBackupService(),
        backupRepository: repository,
      );

      final result = await manager.resetKeys(
        'user-1',
        askNewPin: () async => '123456',
      );

      expect(result, ResetKeysResult.reset);
      expect(repository.saved, hasLength(1));
      expect(keys.savedKeyPairs, 1);
      expect(keys.publicKeyUploads, 1);
    });

    test(
      'keeps the old local keys when the server rejects the backup',
      () async {
        final keys = _FakeKeyService();
        final repository = _FakeBackupRepository()
          ..saveError = Exception('500');
        final manager = E2eeKeyManager(
          keyService: keys,
          backupService: _FakeBackupService(),
          backupRepository: repository,
        );

        final result = await manager.resetKeys(
          'user-1',
          askNewPin: () async => '123456',
        );

        expect(result, ResetKeysResult.saveFailed);
        expect(keys.savedKeyPairs, 0);
      },
    );

    test('changes nothing when the user cancels the PIN prompt', () async {
      final keys = _FakeKeyService();
      final manager = E2eeKeyManager(
        keyService: keys,
        backupService: _FakeBackupService(),
        backupRepository: _FakeBackupRepository(),
      );

      final result = await manager.resetKeys(
        'user-1',
        askNewPin: () async => null,
      );

      expect(result, ResetKeysResult.cancelled);
      expect(keys.savedKeyPairs, 0);
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
        askPin: ({required bool isNewPin}) async => fail('must not ask'),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.publicKeyUploads, 1);
      expect(repository.saved, isEmpty);
    });

    test('keys from before per-account storage are reused', () async {
      keys.hasLegacy = true;

      final result = await service.initialize(
        'u1',
        askPin: ({required bool isNewPin}) async => fail('must not ask'),
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 0);
    });

    test('first use creates keys and a PIN-protected backup', () async {
      bool? askedForNewPin;

      final result = await service.initialize(
        'u1',
        askPin: ({required bool isNewPin}) async {
          askedForNewPin = isNewPin;
          return '123456';
        },
      );

      expect(result, E2eeSetupResult.ready);
      expect(askedForNewPin, isTrue);
      expect(keys.savedKeyPairs, 1);
      expect(repository.saved, hasLength(1));
      expect(keys.publicKeyUploads, 1);
    });

    test('a new device restores the backup with the PIN', () async {
      repository.stored = existingBackup;

      final result = await service.initialize(
        'u1',
        askPin: ({required bool isNewPin}) async {
          expect(isNewPin, isFalse);
          return '123456';
        },
      );

      expect(result, E2eeSetupResult.ready);
      expect(keys.savedKeyPairs, 1);
    });

    test('a wrong PIN restores nothing', () async {
      repository.stored = existingBackup;
      backups.pinIsCorrect = false;

      final result = await service.initialize(
        'u1',
        askPin: ({required bool isNewPin}) async => '000000',
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
        askPin: ({required bool isNewPin}) async => '123456',
      );

      expect(result, E2eeSetupResult.failed);
      expect(keys.savedKeyPairs, 0);
      expect(keys.publicKeyUploads, 0);
    });

    test('cancelling the restore prompt does nothing', () async {
      repository.stored = existingBackup;

      final result = await service.initialize(
        'u1',
        askPin: ({required bool isNewPin}) async => null,
      );

      expect(result, E2eeSetupResult.cancelled);
      expect(keys.savedKeyPairs, 0);
    });

    test('maps server rate limiting and other failures', () async {
      repository.fetchError = const BackupRateLimitedException();
      expect(
        await service.initialize(
          'u1',
          askPin: ({required bool isNewPin}) async => '1',
        ),
        E2eeSetupResult.rateLimited,
      );

      repository.fetchError = Exception('boom');
      expect(
        await service.initialize(
          'u1',
          askPin: ({required bool isNewPin}) async => '1',
        ),
        E2eeSetupResult.failed,
      );
    });
  });
}
