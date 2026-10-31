import 'dart:math';

import 'package:dio/dio.dart';

import 'network_status.dart';

/// Repeats a read that failed for a reason that may pass: no connection for
/// a moment, a timeout, or a gateway that could not reach a service. A weak
/// mobile signal drops single requests often; one quiet retry spares the
/// user an error screen.
///
/// Only reads (GET) are repeated, as repeating them changes nothing on the
/// server. A write is never repeated: the server may have done it already.
///
/// A read sent while [status] already knows the server cannot be reached is
/// not repeated for failing to connect: the outage is not a passing drop,
/// and the screen should say so at once instead of after every repeat.
class RetryInterceptor extends Interceptor {
  /// Put `{noRetry: true}` in a request's `extra` to fail it at once.
  static const noRetry = 'api_no_retry';

  static const _attemptKey = 'api_retry_attempt';
  static const _sentOfflineKey = 'api_retry_sent_offline';

  /// Waits before each repeat; their count is how many repeats are made.
  /// Randomised a little so many phones do not all retry at the same moment.
  final List<Duration> delays;

  final Dio dio;
  final NetworkStatus status;
  final Random _random;

  RetryInterceptor(
    this.dio, {
    required this.status,
    this.delays = const [Duration(seconds: 1), Duration(seconds: 3)],
    Random? random,
  }) : _random = random ?? Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only the first attempt counts: a repeat is sent after the failure
    // that made the status offline.
    options.extra.putIfAbsent(_sentOfflineKey, () => status.isOffline);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = options.extra[_attemptKey] as int? ?? 0;
    if (attempt >= delays.length || !_shouldRetry(err)) {
      return handler.next(err);
    }

    await Future<void>.delayed(_withJitter(delays[attempt]));
    // Given up on while waiting (a newer search replaced it).
    if (options.cancelToken?.isCancelled ?? false) return handler.next(err);

    options.extra[_attemptKey] = attempt + 1;
    try {
      // Goes through every interceptor again, this one included, so a
      // failed repeat is repeated until [delays] run out.
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (repeatError) {
      handler.next(repeatError);
    }
  }

  static bool _shouldRetry(DioException err) {
    final options = err.requestOptions;
    if (options.extra[noRetry] == true) return false;
    if (options.method.toUpperCase() != 'GET') return false;
    return switch (err.type) {
      DioExceptionType.connectionError || DioExceptionType.connectionTimeout =>
        options.extra[_sentOfflineKey] != true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.badResponse => _isPassingServerError(
        err.response?.statusCode,
      ),
      _ => false,
    };
  }

  /// The gateway could not reach a service, or a service was restarting.
  static bool _isPassingServerError(int? status) =>
      status == 502 || status == 503 || status == 504;

  Duration _withJitter(Duration delay) =>
      delay * (0.8 + _random.nextDouble() * 0.4);
}
