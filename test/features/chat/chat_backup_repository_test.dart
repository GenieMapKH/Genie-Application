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
    });
  });

  test('fetchPublicKey reads the key of the given user', () async {
    final adapter = _StubAdapter(200, '{"identityPublicKey":"pub-key"}');
    final repository = _repositoryWith(adapter);

    expect(await repository.fetchPublicKey('user-7'), 'pub-key');
    expect(adapter.lastRequest!.path, '/chat/keys/user-7');
  });
}
