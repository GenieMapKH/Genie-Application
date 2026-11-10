import 'package:flutter/foundation.dart';

import 'package:tilomnov/core/observability/error_reporting.dart';

/// Debug-only logging. Nothing is printed in release builds, so tokens,
/// request bodies and other user data can never leak through device logs.
/// Errors also go to [ErrorReporting.caught], so a bug the app caught is
/// still seen in production.
///
/// Never pass secrets, tokens or personal data in a message.
abstract final class AppLogger {
  static void debug(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    ErrorReporting.caught(message, error, stackTrace);
    if (!kDebugMode) return;
    debugPrint(error == null ? message : '$message: $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
