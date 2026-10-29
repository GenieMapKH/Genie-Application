import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/config/app_config.dart';
import 'package:tilomnov/core/network/api_client.dart';
import 'package:tilomnov/core/network/api_version_interceptor.dart';

/// Answers every request with [status] and [body], and remembers the URLs.
class _Api implements HttpClientAdapter {
  _Api(this.status, this.body);

  final int status;
  final Map<String, Object> body;
  final List<Uri> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.uri);
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
  group('ApiVersionInterceptor', () {
    Future<int> retiredCalls(int status, Map<String, Object> body) async {
      var retired = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = _Api(status, body)
        ..interceptors.add(ApiVersionInterceptor(onRetired: () => retired++));

      await expectLater(
        dio.get<void>('/properties'),
        throwsA(isA<DioException>()),
      );
      return retired;
    }

    test(
      'reports a retired API version, and the request still fails',
      () async {
        expect(await retiredCalls(410, {'code': 'api_version_retired'}), 1);
      },
    );

    test('ignores other failures', () async {
      expect(await retiredCalls(410, {'message': 'Gone'}), 0);
      expect(await retiredCalls(404, {'code': 'api_version_retired'}), 0);
      expect(await retiredCalls(500, {'message': 'boom'}), 0);
    });
  });

  group('the API client', () {
    // Signed out: the client reads the stored tokens before each request.
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('calls every path under this build API version', () async {
      final api = _Api(200, {'ok': true});
      final dio = createApiClient()..httpClientAdapter = api;

      await dio.get<void>('/users/me');

      expect(
        AppConfig.apiUrl,
        '${AppConfig.apiBaseUrl}/v${AppConfig.apiVersion}',
      );
      expect(
        api.calls.single.toString(),
        '${AppConfig.apiBaseUrl}/v1/users/me',
      );
    });

    test('tells the app when the server has retired its API version', () async {
      var retired = false;
      final dio = createApiClient(onApiVersionRetired: () => retired = true)
        ..httpClientAdapter = _Api(410, {'code': 'api_version_retired'});

      await expectLater(dio.get<void>('/feed'), throwsA(isA<DioException>()));

      expect(retired, isTrue);
    });
  });
}
