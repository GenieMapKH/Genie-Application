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
  test('fetchBackup returns the stored backup', () async {
    final repository = _repositoryWith(
      _StubAdapter(
        200,
        '{"backupBlob":"blob","backupSalt":"salt","backupNonce":"nonce"}',
      ),
    );

    final backup = await repository.fetchBackup();

    expect(backup!.blob, 'blob');
    expect(backup.salt, 'salt');
    expect(backup.nonce, 'nonce');
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

  test('saveBackup posts all three fields', () async {
    final adapter = _StubAdapter(201);
    final repository = _repositoryWith(adapter);

    await repository.saveBackup(
      const EncryptedBackup(blob: 'b', salt: 's', nonce: 'n'),
    );

    expect(adapter.lastRequest!.path, '/chat/backup');
    expect(adapter.lastRequest!.data, {
      'backupBlob': 'b',
      'backupSalt': 's',
      'backupNonce': 'n',
    });
  });

  test('fetchPublicKey reads the key of the given user', () async {
    final adapter = _StubAdapter(200, '{"identityPublicKey":"pub-key"}');
    final repository = _repositoryWith(adapter);

    expect(await repository.fetchPublicKey('user-7'), 'pub-key');
    expect(adapter.lastRequest!.path, '/chat/keys/user-7');
  });
}
