import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry/sentry.dart';

import 'package:tilomnov/core/config/app_config.dart';
import 'package:tilomnov/core/errors/app_exceptions.dart';

/// Error reports, sent to Sentry when the build was given a `SENTRY_DSN`;
/// otherwise nothing is sent. Reported: what the app did not catch, and
/// caught errors that point to a bug in the app ([caught]). Not reported:
/// what the connection or the server explains (offline, a refused or failed
/// request); the user is told, and it only leaves a breadcrumb.
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

  /// An error the app caught and handled; [where] says what was being done
  /// ("Could not save the profile"), never with personal data in it.
  static void caught(String where, Object? error, StackTrace? stackTrace) {
    if (!isEnabled) return;
    if (error == null || isExpected(error)) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: where,
          category: 'caught',
          level: SentryLevel.warning,
        ),
      );
      return;
    }
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('caught', where),
    );
  }

  /// Whether [error] is a failure the app expects now and then, not a bug:
  /// a request that failed or was refused, a timeout, or the phone saying
  /// no (a permission, a cancelled picker).
  @visibleForTesting
  static bool isExpected(Object error) =>
      error is DioException ||
      error is AppException ||
      error is TimeoutException ||
      error is PlatformException;

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
