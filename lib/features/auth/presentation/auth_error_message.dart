import 'package:tilomnov/core/errors/app_exceptions.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// What went wrong with signing in or up, or resetting a password, in the
/// user's language. The server's own message is English and meant for
/// developers, so only its status is used. [badRequest] replaces the
/// message for `400`, e.g. a wrong code on the code screen. No internet, a
/// slow connection or a server in trouble are said as everywhere else.
String authErrorMessage(
  AppLocalizations l10n,
  Object error, {
  String? badRequest,
}) {
  final code = error is AppException ? error.code : null;
  return switch (code) {
    '401' || '403' => l10n.authErrorWrongCredentials,
    '409' => l10n.authErrorAccountExists,
    '400' => badRequest ?? l10n.authErrorCheckDetails,
    '429' => l10n.authErrorTooManyTries,
    _ => failureMessage(
      l10n,
      error: error,
      // No answer at all, for a reason the connection does not explain.
      fallback: error is NetworkException && (code == null || code == 'null')
          ? l10n.authErrorNoConnection
          : l10n.authErrorGeneric,
    ),
  };
}
