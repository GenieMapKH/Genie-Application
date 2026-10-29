import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';
import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/core/network/network_status_interceptor.dart';
import 'package:tilomnov/core/network/retry_interceptor.dart';

/// Fails the first [failures] requests the way it is told, then answers.
class _FlakyServer extends Interceptor {
  final calls = <String>[];
  int failures = 0;
  DioExceptionType failWith = DioExceptionType.connectionError;
  int? failStatus;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    calls.add('${options.method} ${options.path}');
    if (failures > 0) {
      failures--;
      return handler.reject(
        DioException(
          requestOptions: options,
          type: failStatus == null ? failWith : DioExceptionType.badResponse,
          response: failStatus == null
              ? null
              : Response(requestOptions: options, statusCode: failStatus),
        ),
        true,
      );
    }
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: 'ok'),
      true,
    );
  }
}

void main() {
  late Dio dio;
  late _FlakyServer server;
  final status = NetworkStatus.instance;

  setUp(() {
    ApiCacheManager().clearAll();
    status.reachable();
    server = _FlakyServer();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.interceptors.addAll([
      NetworkStatusInterceptor(status),
      CacheInterceptor(),
      RetryInterceptor(
        dio,
        delays: const [Duration(milliseconds: 1), Duration(milliseconds: 1)],
        random: Random(1),
      ),
      server,
    ]);
  });

  tearDown(status.reachable);

  test('a read that could not connect is repeated until it works', () async {
    server.failures = 2;

    final answer = await dio.get('/properties/1');

    expect(answer.data, 'ok');
    expect(server.calls, hasLength(3));
    expect(status.online.value, isTrue);
  });

  test('gives up after the last repeat and reports offline', () async {
    server.failures = 5;

    await expectLater(
      dio.get('/properties/1'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(server.calls, hasLength(3));
    expect(status.online.value, isFalse);
  });

  test('repeats a read the gateway could not pass on (503)', () async {
    server
      ..failures = 1
      ..failStatus = 503;

    expect((await dio.get('/properties/1')).data, 'ok');
    expect(server.calls, hasLength(2));
  });

  test('never repeats a write: the server may have done it', () async {
    server.failures = 1;

    await expectLater(
      dio.post('/properties/1/favorite'),
      throwsA(isA<DioException>()),
    );
    expect(server.calls, ['POST /properties/1/favorite']);
  });

  test('does not repeat a refusal (404)', () async {
    server
      ..failures = 1
      ..failStatus = 404;

    await expectLater(dio.get('/properties/1'), throwsA(isA<DioException>()));
    expect(server.calls, hasLength(1));
    expect(status.online.value, isTrue);
  });

  test('noRetry fails at once', () async {
    server.failures = 1;

    await expectLater(
      dio.get(
        '/health',
        options: Options(extra: {RetryInterceptor.noRetry: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(server.calls, hasLength(1));
  });

  test('offline with a kept answer: shown at once, without repeats', () async {
    await dio.get('/properties/1');
    server.calls.clear();
    server.failures = 5;

    final answer = await dio.get('/properties/1');

    expect(answer.data, 'ok');
    expect(server.calls, hasLength(1));
    expect(status.online.value, isFalse);
  });

  test('a cancelled read is not repeated', () async {
    server
      ..failures = 1
      ..failWith = DioExceptionType.cancel;

    await expectLater(dio.get('/properties/1'), throwsA(isA<DioException>()));
    expect(server.calls, hasLength(1));
  });
}
