import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/network/load_failure.dart';
import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/core/network/slow_connection_interceptor.dart';

/// Answers each request after [delay].
class _SlowServer extends Interceptor {
  Duration delay = Duration.zero;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Future<void>.delayed(delay, () {
      handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: 'ok'),
        true,
      );
    });
  }
}

DioException _failure(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
        ),
);

void main() {
  final status = NetworkStatus.instance;

  setUp(status.reset);
  tearDown(status.reset);

  void slowReads(int count) {
    for (var i = 0; i < count; i++) {
      status.slow();
    }
  }

  group('NetworkStatus', () {
    test('weak only after several slow reads in a row', () {
      slowReads(NetworkStatus.slowReadsForWeak - 1);
      expect(status.connection.value, ConnectionQuality.good);
      status.slow();
      expect(status.connection.value, ConnectionQuality.weak);
    });

    test('a quick read starts the count again and ends weak', () {
      slowReads(NetworkStatus.slowReadsForWeak - 1);
      status.quick();
      slowReads(NetworkStatus.slowReadsForWeak - 1);
      expect(status.connection.value, ConnectionQuality.good);

      status.slow();
      expect(status.connection.value, ConnectionQuality.weak);
      status.quick();
      expect(status.connection.value, ConnectionQuality.good);
    });

    testWidgets('weak passes by itself', (tester) async {
      slowReads(NetworkStatus.slowReadsForWeak);
      expect(status.connection.value, ConnectionQuality.weak);
      await tester.pump(const Duration(seconds: 21));
      expect(status.connection.value, ConnectionQuality.good);
    });

    test('an answer ends offline but not weak', () {
      slowReads(NetworkStatus.slowReadsForWeak);
      status.reachable();
      expect(status.connection.value, ConnectionQuality.weak);

      status.unreachable();
      status.reachable();
      expect(status.connection.value, ConnectionQuality.good);
    });

    test('a slow request does not hide that the server is unreachable', () {
      status.unreachable();
      slowReads(NetworkStatus.slowReadsForWeak);
      expect(status.connection.value, ConnectionQuality.offline);
    });
  });

  group('SlowConnectionInterceptor', () {
    late Dio dio;
    late _SlowServer server;

    setUp(() {
      server = _SlowServer();
      dio = Dio()
        ..interceptors.addAll([
          SlowConnectionInterceptor(
            status,
            slowAfter: const Duration(milliseconds: 100),
          ),
          server,
        ]);
    });

    Future<void> reads(int count) async {
      for (var i = 0; i < count; i++) {
        await dio.get<void>('/feed');
      }
    }

    test('slow reads in a row make the connection weak', () async {
      server.delay = const Duration(milliseconds: 150);
      await reads(NetworkStatus.slowReadsForWeak - 1);
      expect(status.connection.value, ConnectionQuality.good);
      await reads(1);
      expect(status.connection.value, ConnectionQuality.weak);
    });

    test('a read still waiting counts once, not again when it ends', () async {
      // Each waits past slowAfter (counted then) and is answered late.
      server.delay = const Duration(milliseconds: 300);
      await reads(NetworkStatus.slowReadsForWeak - 1);
      expect(status.connection.value, ConnectionQuality.good);
    });

    test('a quick read in between starts the count again', () async {
      server.delay = const Duration(milliseconds: 150);
      await reads(NetworkStatus.slowReadsForWeak - 1);
      server.delay = Duration.zero;
      await reads(1);
      server.delay = const Duration(milliseconds: 150);
      await reads(NetworkStatus.slowReadsForWeak - 1);
      expect(status.connection.value, ConnectionQuality.good);
    });

    test('uploads are not timed: they may take long on a good line', () async {
      server.delay = const Duration(milliseconds: 300);
      for (var i = 0; i < NetworkStatus.slowReadsForWeak; i++) {
        await dio.post<void>('/properties/1/images');
      }
      expect(status.connection.value, ConnectionQuality.good);
    });
  });

  test('LoadFailure.of tells the connection apart from the server', () {
    expect(
      LoadFailure.of(_failure(DioExceptionType.connectionError)),
      LoadFailure.offline,
    );
    expect(
      LoadFailure.of(_failure(DioExceptionType.connectionTimeout)),
      LoadFailure.offline,
    );
    expect(
      LoadFailure.of(_failure(DioExceptionType.receiveTimeout)),
      LoadFailure.slow,
    );
    expect(
      LoadFailure.of(_failure(DioExceptionType.badResponse, status: 503)),
      LoadFailure.server,
    );
    expect(
      LoadFailure.of(_failure(DioExceptionType.badResponse, status: 404)),
      LoadFailure.other,
    );
    expect(LoadFailure.of(StateError('x')), LoadFailure.other);
  });
}
