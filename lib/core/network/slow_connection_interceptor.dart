import 'dart:async';

import 'package:dio/dio.dart';

import 'network_status.dart';
import 'network_status_interceptor.dart';

/// Tells [NetworkStatus] how long reads take: [NetworkStatus.slow] for one
/// still waiting after [slowAfter] (once per request, however long it then
/// takes), [NetworkStatus.quick] for one answered sooner.
///
/// Only reads of JSON are timed: their answers are small, so a long wait
/// means a weak signal. Uploads and file downloads may take long on a good
/// connection too. A request that could not connect is not timed: that is
/// offline, not slow.
///
/// [slowAfter] is long on purpose: an ordinary mobile connection answers in
/// a second or two, and only a very weak one (a rural signal, a data plan
/// almost used up) keeps a small answer waiting this long.
///
/// Added after the cache, so answers kept in memory are never timed.
class SlowConnectionInterceptor extends Interceptor {
  static const _startedKey = 'slow_connection_started';
  static const _timerKey = 'slow_connection_timer';
  static const _countedKey = 'slow_connection_counted';

  final NetworkStatus status;
  final Duration slowAfter;

  SlowConnectionInterceptor(
    this.status, {
    this.slowAfter = const Duration(seconds: 10),
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // A repeat (retry, renewed session) sends the same options again.
    _stop(options);
    if (_isTimed(options)) {
      options.extra[_startedKey] = DateTime.now();
      options.extra[_timerKey] = Timer(slowAfter, () {
        options.extra[_countedKey] = true;
        status.slow();
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
    if (NetworkStatusInterceptor.isUnreachable(err)) {
      _stop(err.requestOptions);
    } else {
      _finish(err.requestOptions);
    }
    handler.next(err);
  }

  void _finish(RequestOptions options) {
    final started = options.extra[_startedKey];
    final counted = options.extra[_countedKey] == true;
    _stop(options);
    if (started is! DateTime || counted) return;
    if (DateTime.now().difference(started) >= slowAfter) {
      status.slow();
    } else {
      status.quick();
    }
  }

  static void _stop(RequestOptions options) {
    (options.extra.remove(_timerKey) as Timer?)?.cancel();
    options.extra.remove(_startedKey);
    options.extra.remove(_countedKey);
  }

  static bool _isTimed(RequestOptions options) =>
      options.method.toUpperCase() == 'GET' &&
      options.responseType == ResponseType.json;
}
