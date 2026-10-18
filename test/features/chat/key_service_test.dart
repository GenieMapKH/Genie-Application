import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/e2ee/keys/crypto_service.dart';
import 'package:genie/features/chat/e2ee/keys/key_service.dart';
import 'package:sodium_libs/sodium_libs.dart';

class _FakeCrypto extends Fake implements CryptoService {}

class _FakeSecretKey extends Fake implements SecureKey {
  @override
  Uint8List extractBytes() => Uint8List.fromList([1, 2, 3]);
}

class _GeneratingCrypto extends Fake implements CryptoService {
  @override
  KeyPair generateKeyPair() => KeyPair(
    publicKey: Uint8List.fromList([9]),
    secretKey: _FakeSecretKey(),
  );
}

/// Answers `GET /chat/keys/:id` with the public key the server lists, and
/// `POST /chat/keys` with [uploadStatus].
class _KeyServer implements HttpClientAdapter {
  final Map<String, String> publicKeys;
  final int uploadStatus;
  int uploads = 0;

  _KeyServer(this.publicKeys, {this.uploadStatus = 201});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST') {
      uploads++;
      return ResponseBody.fromString(
        '{}',
        uploadStatus,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
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

  group('publishing the public key', () {
    const aliceKeys = {
      'identity_public_key_alice': 'alice-public',
      'identity_private_key_alice': 'alice-private',
    };

    KeyService serviceOn(_KeyServer server) => KeyService(
      cryptoService: _FakeCrypto(),
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = server,
    );

    test('uploads it when the server has none', () async {
      FlutterSecureStorage.setMockInitialValues({...aliceKeys});
      final server = _KeyServer({});

      expect(
        await serviceOn(server).publishPublicKeyIfMissing('alice'),
        isTrue,
      );
      expect(server.uploads, 1);
    });

    test('does nothing when the server already lists it', () async {
      FlutterSecureStorage.setMockInitialValues({...aliceKeys});
      final server = _KeyServer({'alice': 'alice-public'});

      expect(
        await serviceOn(server).publishPublicKeyIfMissing('alice'),
        isTrue,
      );
      expect(server.uploads, 0);
    });

    test(
      'never replaces a key another device published since',
      () async {
        FlutterSecureStorage.setMockInitialValues({...aliceKeys});
        // Without a backup PIN the server would take it: two devices would
        // then keep replacing each other's key.
        final server = _KeyServer({'alice': 'newer-public'});

        expect(
          await serviceOn(server).publishPublicKeyIfMissing('alice'),
          isFalse,
        );
        expect(server.uploads, 0);
      },
    );

    test('a server failure is not mistaken for replaced keys', () async {
      FlutterSecureStorage.setMockInitialValues({...aliceKeys});
      final server = _KeyServer({}, uploadStatus: 500);

      expect(
        await serviceOn(server).publishPublicKeyIfMissing('alice'),
        isTrue,
      );
    });
  });

  group('a new key pair', () {
    KeyService serviceOn(_KeyServer server) => KeyService(
      cryptoService: _GeneratingCrypto(),
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = server,
    );

    test('replaces the key the server lists, and is kept here', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final server = _KeyServer({'alice': 'old-public'});

      await serviceOn(server).createAndPublishKeyPair('alice');

      expect(server.uploads, 1);
      expect(await serviceOn(server).hasLocalKeyPair('alice'), isTrue);
    });

    test('is not kept when the server did not take it', () async {
      FlutterSecureStorage.setMockInitialValues({});
      // 409: a backup PIN protects the account's keys.
      final server = _KeyServer({}, uploadStatus: 409);

      await expectLater(
        serviceOn(server).createAndPublishKeyPair('alice'),
        throwsA(isA<DioException>()),
      );
      expect(await serviceOn(server).hasLocalKeyPair('alice'), isFalse);
    });
  });

  test('there is nothing to adopt on a fresh install', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final service = _serviceWith({'alice': 'alice-public'});

    expect(await service.adoptLegacyKeyPair('alice'), isFalse);
  });
}
