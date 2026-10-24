import 'package:dio/dio.dart';

import 'network_status.dart';

/// Tells [NetworkStatus] what every request found. Added first, so it sees
/// each failure before the cache answers it with a kept copy.
class NetworkStatusInterceptor extends Interceptor {
  final NetworkStatus status;

  NetworkStatusInterceptor(this.status);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    status.reachable();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      // The server answered, even if with an error.
      status.reachable();
    } else if (isUnreachable(err)) {
      status.unreachable();
    }
    handler.next(err);
  }

  /// The request never reached the server, or the server never answered.
  static bool isUnreachable(DioException err) => switch (err.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout => true,
    _ => false,
  };
}
