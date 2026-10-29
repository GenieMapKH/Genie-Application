import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/network/safe_log_interceptor.dart';

/// Answers every request with [status] and an empty JSON body.
class _StubAdapter implements HttpClientAdapter {
  final int status;

  _StubAdapter(this.status);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"accessToken":"secret-access-token"}',
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
  late List<String> logs;
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    logs = [];
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
  });

  tearDown(() => debugPrint = originalDebugPrint);

  Dio dioReturning(int status) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _StubAdapter(status);
    dio.interceptors.add(SafeLogInterceptor());
    return dio;
  }

  test('logs method, path and status of a successful call', () async {
    await dioReturning(200).post('/auth/login', data: {'password': 'x'});

    expect(logs, hasLength(1));
    expect(logs.single, contains('200'));
    expect(logs.single, contains('POST /auth/login'));
  });

  test('never prints tokens, passwords or response bodies', () async {
    await dioReturning(200).post(
      '/auth/login',
      data: {'email': 'a@b.com', 'password': 'my-secret-password'},
      options: Options(headers: {'Authorization': 'Bearer top-secret-jwt'}),
    );

    final output = logs.join('\n');
    expect(output, isNot(contains('my-secret-password')));
    expect(output, isNot(contains('top-secret-jwt')));
    expect(output, isNot(contains('Bearer')));
    expect(output, isNot(contains('secret-access-token')));
    expect(output, isNot(contains('a@b.com')));
  });

  test('logs failures with their status code only', () async {
    await expectLater(
      dioReturning(401).get('/users/me'),
      throwsA(isA<DioException>()),
    );

    expect(logs.single, contains('401'));
    expect(logs.single, contains('GET /users/me'));
  });
}
