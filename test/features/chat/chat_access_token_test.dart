import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/data/chat_access_token.dart';

/// A token that only needs a readable `exp`; nothing here checks signatures.
String _tokenExpiring(Duration fromNow) {
  final payload = {
    'sub': 'user-1',
    'exp': DateTime.now().add(fromNow).millisecondsSinceEpoch ~/ 1000,
  };
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return 'header.${body.replaceAll('=', '')}.signature';
}

/// Stands in for the API client: a request to it renews the stored session,
/// as the real client does when the server answers 401.
class _RenewingApi implements HttpClientAdapter {
  final String renewedToken;
  final requests = <String>[];
  bool offline = false;

  _RenewingApi(this.renewedToken);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.path);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    await const FlutterSecureStorage().write(
      key: 'access_token',
      value: renewedToken,
    );
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final renewed = _tokenExpiring(const Duration(minutes: 15));
  late _RenewingApi api;
  late ChatAccessToken source;

  void storeToken(String? token) {
    FlutterSecureStorage.setMockInitialValues({'access_token': ?token});
  }

  setUp(() {
    api = _RenewingApi(renewed);
    source = ChatAccessToken(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = api,
    );
  });

  test('a valid token is used as it is, without asking the server', () async {
    final valid = _tokenExpiring(const Duration(minutes: 10));
    storeToken(valid);

    expect(await source.read(), valid);
    expect(api.requests, isEmpty);
  });

  test('an expired token is renewed first', () async {
    storeToken(_tokenExpiring(const Duration(minutes: -1)));

    expect(await source.read(), renewed);
    expect(api.requests, ['/users/me']);
  });

  test('a token about to expire is renewed too', () async {
    storeToken(_tokenExpiring(const Duration(seconds: 10)));

    expect(await source.read(), renewed);
  });

  test(
    'a token the server refused is renewed even if it looks valid',
    () async {
      // The server's clock decides, e.g. when it runs ahead of this phone.
      storeToken(_tokenExpiring(const Duration(minutes: 1)));

      expect(await source.read(afterRejection: true), renewed);
      expect(api.requests, ['/users/me']);
    },
  );

  test('signed out means no token and no request', () async {
    storeToken(null);

    expect(await source.read(afterRejection: true), isNull);
    expect(api.requests, isEmpty);
  });

  test('offline, the stored token is returned rather than failing', () async {
    final expired = _tokenExpiring(const Duration(minutes: -1));
    storeToken(expired);
    api.offline = true;

    expect(await source.read(), expired);
  });
}
