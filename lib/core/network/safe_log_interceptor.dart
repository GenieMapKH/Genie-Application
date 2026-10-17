import 'package:dio/dio.dart';
import 'package:genie/core/logging/app_logger.dart';

/// Logs one line per request and response: method, path, status and duration.
///
/// Unlike Dio's `LogInterceptor` it never prints headers or bodies, which carry
/// the bearer token, passwords, OTP codes and chat ciphertext.
class SafeLogInterceptor extends Interceptor {
  static const _startedAtKey = 'safe_log_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '<-- ${response.statusCode} ${_describe(response.requestOptions)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode ?? err.type.name;
    AppLogger.debug('<-- $status ${_describe(err.requestOptions)}');
    handler.next(err);
  }

  String _describe(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey] as int?;
    final took = startedAt == null
        ? ''
        : ' (${DateTime.now().millisecondsSinceEpoch - startedAt}ms)';
    return '${options.method} ${options.uri.path}$took';
  }
}
