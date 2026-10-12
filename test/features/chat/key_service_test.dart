import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/e2ee/crypto_service.dart';
import 'package:genie/features/chat/e2ee/key_service.dart';

class _FakeCrypto extends Fake implements CryptoService {}

/// Answers `GET /chat/keys/:id` with the public key the server lists.
class _KeyServer implements HttpClientAdapter {
  final Map<String, String> publicKeys;

  _KeyServer(this.publicKeys);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = publicKeys[options.path.split('/').last];
    return ResponseBody.fromString(
      key == null ? '{}' : '{"identityPublicKey":"$key"}',
      key == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

KeyService _serviceWith(Map<String, String> serverKeys) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = _KeyServer(serverKeys);
  return KeyService(cryptoService: _FakeCrypto(), dio: dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const legacyKeys = {
    'identity_public_key': 'legacy-public',
    'identity_private_key': 'legacy-private',
  };

  test("one account's keys are not visible to another account", () async {
    FlutterSecureStorage.setMockInitialValues({
      'identity_public_key_alice': 'alice-public',
      'identity_private_key_alice': 'alice-private',
    });
    final service = _serviceWith({});

    expect(await service.hasLocalKeyPair('alice'), isTrue);
    expect(await service.hasLocalKeyPair('bob'), isFalse);
  });

  group('the old per-device key pair', () {
    test('moves to the account the server lists it under', () async {
      FlutterSecureStorage.setMockInitialValues({...legacyKeys});
      final service = _serviceWith({'alice': 'legacy-public'});

      expect(await service.adoptLegacyKeyPair('alice'), isTrue);
      expect(await service.hasLocalKeyPair('alice'), isTrue);
    });

    test('can only be adopted once', () async {
      FlutterSecureStorage.setMockInitialValues({...legacyKeys});
      final service = _serviceWith({
        'alice': 'legacy-public',
        'bob': 'legacy-public',
      });

      await service.adoptLegacyKeyPair('alice');

      expect(await service.adoptLegacyKeyPair('bob'), isFalse);
      expect(await service.hasLocalKeyPair('bob'), isFalse);
    });

    test('is not given to an account with a different key', () async {
      FlutterSecureStorage.setMockInitialValues({...legacyKeys});
      final service = _serviceWith({'bob': 'bob-public'});

      expect(await service.adoptLegacyKeyPair('bob'), isFalse);
      expect(await service.hasLocalKeyPair('bob'), isFalse);
    });

    test('is not given to an account with no key on the server', () async {
      FlutterSecureStorage.setMockInitialValues({...legacyKeys});
      final service = _serviceWith({});

      expect(await service.adoptLegacyKeyPair('carol'), isFalse);
    });
  });

  test('there is nothing to adopt on a fresh install', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final service = _serviceWith({'alice': 'alice-public'});

    expect(await service.adoptLegacyKeyPair('alice'), isFalse);
  });
}
