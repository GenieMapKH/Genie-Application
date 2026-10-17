import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/network/api_cache_manager.dart';

/// Answers every request itself and counts what reached "the server".
class _FakeServer extends Interceptor {
  final calls = <String>[];
  int version = 1;
  bool offline = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    calls.add('${options.method} ${options.path}');
    if (offline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
        true,
      );
    }
    final etag = 'v$version';
    if (options.headers['If-None-Match'] == etag) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 304),
          type: DioExceptionType.badResponse,
        ),
        true,
      );
    }
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {'version': version},
        headers: Headers.fromMap({
          'etag': [etag],
        }),
      ),
      true,
    );
  }
}

void main() {
  late Dio dio;
  late _FakeServer server;

  setUp(() {
    ApiCacheManager().clearAll();
    server = _FakeServer();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..interceptors.addAll([CacheInterceptor(), server]);
  });

  final fresh = Options(
    extra: CacheInterceptor.freshFor(const Duration(seconds: 30)),
  );

  test('a request marked fresh is answered from memory', () async {
    await dio.get('/public/properties/map', options: fresh);
    final second = await dio.get('/public/properties/map', options: fresh);

    expect(second.data, {'version': 1});
    expect(server.calls, hasLength(1));
  });

  test('an unmarked request still asks the server, with the ETag', () async {
    await dio.get('/properties/my/favorites');
    final second = await dio.get('/properties/my/favorites');

    expect(second.statusCode, 200);
    expect(second.data, {'version': 1});
    expect(server.calls, hasLength(2));
  });

  test('a write drops every kept answer about the same resource', () async {
    await dio.get('/public/properties/map', options: fresh);
    await dio.get('/properties/my/favorites');
    await dio.get('/users/me', options: fresh);

    server.version = 2;
    await dio.post('/properties/42/favorite');

    expect(
      (await dio.get('/public/properties/map', options: fresh)).data,
      {'version': 2},
    );
    expect((await dio.get('/properties/my/favorites')).data, {'version': 2});
    // Another resource is untouched.
    expect((await dio.get('/users/me', options: fresh)).data, {'version': 1});
  });

  test('the kept answer is used when the network is down', () async {
    await dio.get('/properties/my/favorites');
    server.offline = true;

    final answer = await dio.get('/properties/my/favorites');

    expect(answer.data, {'version': 1});
  });

  test('skipCache keeps a request out of the cache', () async {
    final skip = Options(extra: {CacheInterceptor.skipCache: true});
    await dio.get('/public/search', options: skip);
    server.offline = true;

    await expectLater(
      dio.get('/public/search', options: skip),
      throwsA(isA<DioException>()),
    );
  });

  group('resourceOf', () {
    test('skips "public" and the query', () {
      expect(
        ApiCacheManager.resourceOf('/public/properties/map?minLat=1'),
        'properties',
      );
      expect(ApiCacheManager.resourceOf('/properties/42/favorite'), 'properties');
      expect(ApiCacheManager.resourceOf('/users/me'), 'users');
      expect(ApiCacheManager.resourceOf('/'), isNull);
    });
  });

  test('keeps at most 100 answers, dropping the least recently used', () {
    final cache = ApiCacheManager();
    cache.set('/keep', 1);
    for (var i = 0; i < 99; i++) {
      cache.set('/n$i', i);
    }
    cache.get('/keep'); // used: now the most recent
    cache.set('/one-more', 0);

    expect(cache.get('/keep'), isNotNull);
    expect(cache.get('/n0'), isNull);
  });
}
