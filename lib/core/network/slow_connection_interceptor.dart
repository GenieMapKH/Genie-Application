import 'dart:async';

import 'package:dio/dio.dart';

import 'network_status.dart';

/// Confirms a delayed read with the small, uncached health request. A slow
/// endpoint or a parallel startup batch alone does not mean slow internet.
/// Added after the cache, so cached reads never count.
class SlowConnectionInterceptor extends Interceptor {
  static const _startedKey = 'slow_connection_started';
  static const _timerKey = 'slow_connection_timer';
  static const _countedKey = 'slow_connection_counted';

  final NetworkStatus status;
  final Duration slowAfter;
  final Duration probeSlowAfter;
  final Duration checkEvery;
  DateTime? _lastCheck;
  bool _checking = false;

  SlowConnectionInterceptor(
    this.status, {
    this.slowAfter = const Duration(seconds: 15),
    this.probeSlowAfter = const Duration(seconds: 5),
    this.checkEvery = const Duration(seconds: 30),
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // A repeat (retry, renewed session) sends the same options again.
    _stop(options);
    if (_isTimed(options)) {
      options.extra[_startedKey] = DateTime.now();
      options.extra[_timerKey] = Timer(slowAfter, () {
        options.extra[_countedKey] = true;
        unawaited(_confirmSlow());
      });
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finish(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Errors, cancellations and timeouts do not establish network speed.
    _stop(err.requestOptions);
    handler.next(err);
  }

  void _finish(RequestOptions options) {
    final started = options.extra[_startedKey];
    final counted = options.extra[_countedKey] == true;
    _stop(options);
    if (started is! DateTime || counted) return;
    if (DateTime.now().difference(started) >= slowAfter) {
      unawaited(_confirmSlow());
    } else {
      status.quick();
    }
  }

  static void _stop(RequestOptions options) {
    (options.extra.remove(_timerKey) as Timer?)?.cancel();
    options.extra.remove(_startedKey);
    options.extra.remove(_countedKey);
  }

  Future<void> _confirmSlow() async {
    final probe = status.probe;
    final now = DateTime.now();
    if (probe == null ||
        _checking ||
        status.isOffline ||
        (_lastCheck != null && now.difference(_lastCheck!) < checkEvery)) {
      return;
    }
    _checking = true;
    _lastCheck = now;
    final watch = Stopwatch()..start();
    try {
      await probe();
      if (watch.elapsed >= probeSlowAfter) {
        status.slow();
      } else {
        status.quick();
      }
    } on Exception {
      // The regular network interceptor reports an unreachable server.
    } finally {
      _checking = false;
    }
  }

  static bool _isTimed(RequestOptions options) =>
      options.method.toUpperCase() == 'GET' &&
      options.responseType == ResponseType.json &&
      !options.uri.path.endsWith('/health');
}
