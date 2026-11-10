import 'package:dio/dio.dart';
import 'package:tilomnov/core/errors/app_exceptions.dart';

import 'network_status.dart';

/// Why something could not be loaded, in the terms a screen explains it to
/// the user.
enum LoadFailure {
  /// The request never reached the server: no internet or no signal.
  offline,

  /// The server was reached but the answer did not arrive in time: a weak
  /// signal or a crowded network.
  slow,

  /// The server answered that it is in trouble (5xx), or is restarting.
  server,

  /// Anything else; the screen's own message explains it.
  other;

  /// The failure behind [error], as thrown by a repository; an
  /// [AppException] is judged by its cause. With no error at all (the layer
  /// below only said "failed"), the server and connection as the app's last
  /// request found them: a server answer ends offline before the failure
  /// gets here, so offline means the request never arrived.
  static LoadFailure of(Object? error) {
    final cause = error is AppException ? error.cause : error;
    if (cause == null) {
      final status = NetworkStatus.instance;
      if (status.isOffline) return offline;
      return status.serverInTrouble ? server : other;
    }
    if (cause is! DioException) return other;
    switch (cause.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return offline;
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return slow;
      default:
        final status = cause.response?.statusCode ?? 0;
        return status >= 500 ? server : other;
    }
  }

  /// Whether a better connection may be all it takes, so loading again when
  /// the connection comes back is worth it.
  bool get isConnection => this == offline || this == slow;
}
