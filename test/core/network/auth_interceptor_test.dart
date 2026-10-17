import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/network/auth_interceptor.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';

/// Stands in for the API. `/users/me` is served only to [acceptedToken];
/// `/auth/refresh` answers what [refresh] says.
class _Api implements HttpClientAdapter {
  String acceptedToken = 'new-access';

  /// The status of `/auth/refresh`, or null for "cannot be reached".
  int? refresh = 200;

  /// What `/users/me` answers once the token is accepted.
  int profileStatus = 200;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    if (options.path == '/auth/refresh') {
      // Slow enough for other requests to be refused meanwhile.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (refresh == null) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }
      return _json(refresh!, {
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      });
    }
    final signedIn =
        options.headers['Authorization'] == 'Bearer $acceptedToken';
    return _json(signedIn ? profileStatus : 401, {'id': 'me'});
  }

  ResponseBody _json(int status, Map<String, Object> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Api api;
  late Dio dio;
  late int sessionsEnded;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'expired-access',
      'refresh_token': 'old-refresh',
    });
    api = _Api();
    sessionsEnded = 0;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = api;
    dio.interceptors.add(
      AuthInterceptor(dio, onSessionEnded: () => sessionsEnded++),
    );
  });

  test('renews an expired session and repeats the request', () async {
    final response = await dio.get('/users/me');

    expect(response.statusCode, 200);
    expect(api.calls, ['/users/me', '/auth/refresh', '/users/me']);
    expect(await AuthStorage.getAccessToken(), 'new-access');
    expect(await AuthStorage.getRefreshToken(), 'new-refresh');
    expect(sessionsEnded, 0);
  });

  test('a device that was signed out is told so at once', () async {
    // What the server answers after "sign out" was tapped on another device.
    api.refresh = 401;

    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));

    expect(sessionsEnded, 1);
    expect(await AuthStorage.getAccessToken(), isNull);
    expect(await AuthStorage.getRefreshToken(), isNull);
  });

  test('being offline for a moment signs nobody out', () async {
    api.refresh = null;

    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));

    expect(sessionsEnded, 0);
    expect(await AuthStorage.getRefreshToken(), 'old-refresh');
  });

  test(
    'a request that fails after the session was renewed leaves it alone',
    () async {
      api.profileStatus = 500;

      await expectLater(
        dio.get('/users/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            500,
          ),
        ),
      );

      expect(sessionsEnded, 0);
      expect(await AuthStorage.getAccessToken(), 'new-access');
    },
  );

  test('requests refused together share one renewal', () async {
    // The app wakes up with an expired token and asks for several things.
    final responses = await Future.wait([
      dio.get('/users/me'),
      dio.get('/users/me'),
      dio.get('/users/me'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(api.calls.where((path) => path == '/auth/refresh'), hasLength(1));
    expect(sessionsEnded, 0);
  });

  test('a request refused after another renewed is repeated at once', () async {
    await dio.get('/users/me');
    api.calls.clear();

    // Sent with the old token, answered after the renewal.
    final late = dio.get(
      '/users/me',
      options: Options(headers: {'Authorization': 'Bearer expired-access'}),
    );

    expect((await late).statusCode, 200);
    expect(api.calls, isNot(contains('/auth/refresh')));
  });

  test('a repeated request refused again is not renewed again', () async {
    api.acceptedToken = 'never';

    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));

    expect(api.calls, ['/users/me', '/auth/refresh', '/users/me']);
    expect(sessionsEnded, 0);
  });

  test('signing out while the session is renewed keeps it signed out', () async {
    final request = dio.get('/users/me');
    // The renewal is on its way when the user taps "Sign out".
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await AuthStorage.clearTokens();

    await expectLater(request, throwsA(isA<DioException>()));

    expect(api.calls, contains('/auth/refresh'));
    expect(await AuthStorage.getAccessToken(), isNull);
    expect(await AuthStorage.getRefreshToken(), isNull);
    expect(AuthStorage.signedIn.value, isFalse);
    expect(sessionsEnded, 0);
  });

  test('a renewal refused after signing out does not end it twice', () async {
    // Signing out revoked the refresh token the renewal is using.
    api.refresh = 401;
    final request = dio.get('/users/me');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await AuthStorage.clearTokens();

    await expectLater(request, throwsA(isA<DioException>()));

    expect(sessionsEnded, 0);
  });

  test('a guest has no session to renew or to lose', () async {
    FlutterSecureStorage.setMockInitialValues({});

    await expectLater(dio.get('/users/me'), throwsA(isA<DioException>()));

    expect(api.calls, ['/users/me']);
    expect(sessionsEnded, 0);
  });
}
