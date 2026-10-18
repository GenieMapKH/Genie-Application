import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  final int status;
  final String body;
  RequestOptions? lastRequest;

  _StubAdapter(this.status, [this.body = '{}']);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChatBackupRepository _repositoryWith(_StubAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  return ChatBackupRepository(dio: dio);
}

void main() {
  test('fetchBackup learns only the salt of a protected backup', () async {
    final repository = _repositoryWith(
      _StubAdapter(200, '{"backupSalt":"salt"}'),
    );

    final backup = await repository.fetchBackup();

    expect(backup!.salt, 'salt');
    expect(backup.legacyKey, isNull);
  });

  test('fetchBackup still receives an older backup whole', () async {
    final repository = _repositoryWith(
      _StubAdapter(
        200,
        '{"backupBlob":"blob","backupSalt":"salt","backupNonce":"nonce"}',
      ),
    );

    final backup = await repository.fetchBackup();

    expect(backup!.salt, 'salt');
    expect(backup.legacyKey!.blob, 'blob');
    expect(backup.legacyKey!.nonce, 'nonce');
  });

  test('unlockBackup sends the PIN proof and returns the key', () async {
    final adapter = _StubAdapter(
      200,
      '{"backupBlob":"blob","backupNonce":"nonce"}',
    );
    final repository = _repositoryWith(adapter);

    final key = await repository.unlockBackup('proof');

    expect(adapter.lastRequest!.path, '/chat/backup/unlock');
    expect(adapter.lastRequest!.data, {'backupVerifier': 'proof'});
    expect(key.blob, 'blob');
    expect(key.nonce, 'nonce');
  });

  test('unlockBackup tells a wrong PIN from a locked backup', () async {
    await expectLater(
      _repositoryWith(_StubAdapter(403)).unlockBackup('proof'),
      throwsA(isA<WrongPinException>()),
    );
    await expectLater(
      _repositoryWith(_StubAdapter(429)).unlockBackup('proof'),
      throwsA(isA<BackupRateLimitedException>()),
    );
    await expectLater(
      _repositoryWith(_StubAdapter(503)).unlockBackup('proof'),
      throwsA(isA<DioException>()),
    );
  });

  test('a refusal carries what the server says: tries left, or the wait', () async {
    await expectLater(
      _repositoryWith(
        _StubAdapter(403, '{"message":"Wrong PIN","attemptsLeft":2}'),
      ).unlockBackup('proof'),
      throwsA(
        isA<WrongPinException>().having((e) => e.attemptsLeft, 'left', 2),
      ),
    );
    await expectLater(
      _repositoryWith(
        _StubAdapter(429, '{"retryAfterSeconds":900}'),
      ).unlockBackup('proof'),
      throwsA(
        isA<BackupRateLimitedException>().having(
          (e) => e.retryAfter,
          'wait',
          const Duration(minutes: 15),
        ),
      ),
    );
    // A plain refusal, e.g. from the lookup limit, still says what it is.
    await expectLater(
      _repositoryWith(
        _StubAdapter(429, '"Too Many Requests"'),
      ).fetchBackup(),
      throwsA(
        isA<BackupRateLimitedException>().having(
          (e) => e.retryAfter,
          'wait',
          isNull,
        ),
      ),
    );
  });

  test('fetchBackup returns null when the user has no backup yet', () async {
    final repository = _repositoryWith(_StubAdapter(404));

    expect(await repository.fetchBackup(), isNull);
  });

  test('fetchBackup reports rate limiting', () async {
    final repository = _repositoryWith(_StubAdapter(429));

    await expectLater(
      repository.fetchBackup(),
      throwsA(isA<BackupRateLimitedException>()),
    );
  });

  test('fetchBackup rethrows other server errors', () async {
    final repository = _repositoryWith(_StubAdapter(500));

    await expectLater(repository.fetchBackup(), throwsA(isA<DioException>()));
  });

  test('saveBackup posts the backup with its PIN proof', () async {
    final adapter = _StubAdapter(201);
    final repository = _repositoryWith(adapter);

    await repository.saveBackup(
      const EncryptedBackup(blob: 'b', salt: 's', nonce: 'n', verifier: 'v'),
    );

    expect(adapter.lastRequest!.path, '/chat/backup');
    expect(adapter.lastRequest!.data, {
      'backupBlob': 'b',
      'backupSalt': 's',
      'backupNonce': 'n',
      'backupVerifier': 'v',
      'protectedBy': 'pin',
    });
  });

  test('replacing a backup sends the proof of its current PIN', () async {
    final adapter = _StubAdapter(201);
    final repository = _repositoryWith(adapter);

    await repository.saveBackup(
      const EncryptedBackup(blob: 'b', salt: 's', nonce: 'n', verifier: 'v'),
      ownerProof: const BackupOwnerProof.pin('proof-of-current-pin'),
    );

    expect(
      (adapter.lastRequest!.data as Map)['currentBackupVerifier'],
      'proof-of-current-pin',
    );
  });

  test('for a forgotten PIN the password proof is sent instead', () async {
    final adapter = _StubAdapter(201);
    final repository = _repositoryWith(adapter);

    await repository.saveBackup(
      const EncryptedBackup(blob: 'b', salt: 's', nonce: 'n', verifier: 'v'),
      ownerProof: const BackupOwnerProof.password('signed-proof'),
    );

    final sent = adapter.lastRequest!.data as Map;
    expect(sent['passwordProofToken'], 'signed-proof');
    expect(sent.containsKey('currentBackupVerifier'), isFalse);
  });

  test(
    'resetKeys sends the new public key with its backup and the proof',
    () async {
      final adapter = _StubAdapter(200);
      final repository = _repositoryWith(adapter);

      await repository.resetKeys(
        publicKey: 'new-public-key',
        backup: const EncryptedBackup(
          blob: 'b',
          salt: 's',
          nonce: 'n',
          verifier: 'v',
        ),
        ownerProof: const BackupOwnerProof.pin('proof-of-current-pin'),
      );

      expect(adapter.lastRequest!.path, '/chat/keys/reset');
      expect(adapter.lastRequest!.data, {
        'backupBlob': 'b',
        'backupSalt': 's',
        'backupNonce': 'n',
        'backupVerifier': 'v',
        'protectedBy': 'pin',
        'currentBackupVerifier': 'proof-of-current-pin',
        'identityPublicKey': 'new-public-key',
      });
    },
  );

  test('a refused replacement is a wrong PIN or a locked backup', () async {
    const backup = EncryptedBackup(
      blob: 'b',
      salt: 's',
      nonce: 'n',
      verifier: 'v',
    );

    await expectLater(
      _repositoryWith(_StubAdapter(403)).saveBackup(backup),
      throwsA(isA<WrongPinException>()),
    );
    await expectLater(
      _repositoryWith(
        _StubAdapter(429),
      ).resetKeys(publicKey: 'k', backup: backup),
      throwsA(isA<BackupRateLimitedException>()),
    );
  });

  test('fetchPublicKey reads the key of the given user', () async {
    final adapter = _StubAdapter(200, '{"identityPublicKey":"pub-key"}');
    final repository = _repositoryWith(adapter);

    expect(await repository.fetchPublicKey('user-7'), 'pub-key');
    expect(adapter.lastRequest!.path, '/chat/keys/user-7');
  });
}
