import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry/sentry.dart';

import 'package:genie/core/config/app_config.dart';

/// Error reports, sent to Sentry when the build was given a `SENTRY_DSN`;
/// otherwise nothing is sent. Only what the app did not catch is reported:
/// errors it handles (offline, a refused request) are shown to the user, not
/// reported.
///
/// The Dart client (`sentry`), not `sentry_flutter`: it needs no Android code,
/// so the app keeps its minimum Android version. Crashes in native (Java,
/// C) code are not reported.
abstract final class ErrorReporting {
  static bool get isEnabled => AppConfig.sentryDsn.isNotEmpty;

  /// Starts reporting, when configured, then runs [appRunner].
  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (isEnabled) {
      await Sentry.init((options) {
        options
          ..dsn = AppConfig.sentryDsn
          ..environment = AppConfig.sentryEnvironment
          // No IP address: a report says what broke, not who was using it.
          ..sendDefaultPii = false
          // Performance tracing is off: it is billed per event.
          ..tracesSampleRate = 0
          ..beforeSend = (event, _) => withoutPersonalData(event);
      });
      _reportUncaughtErrors();
    }
    return appRunner();
  }

  /// Errors in building and drawing (Flutter's own), and errors no code
  /// awaited. Each is still handled as before: printed, or the red screen in
  /// a debug run.
  static void _reportUncaughtErrors() {
    final flutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterHandler?.call(details);
      Sentry.captureException(details.exception, stackTrace: details.stack);
    };
    final platformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      Sentry.captureException(error, stackTrace: stack);
      return platformHandler?.call(error, stack) ?? false;
    };
  }

  /// [event] without request details or anything about the user but an id.
  /// Chat text never reaches here: it is decrypted on the phone only and
  /// never logged.
  @visibleForTesting
  static SentryEvent withoutPersonalData(SentryEvent event) {
    event.request = null;
    final id = event.user?.id;
    event.user = id == null ? null : SentryUser(id: id);
    return event;
  }
}
