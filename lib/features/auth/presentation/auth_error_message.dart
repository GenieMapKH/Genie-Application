import 'package:tilomnov/core/errors/app_exceptions.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// What went wrong with signing in or up, or resetting a password, in the
/// user's language. The server's own message is English and meant for
/// developers, so only its status is used. [badRequest] replaces the
/// message for `400`, e.g. a wrong code on the code screen.
String authErrorMessage(
  AppLocalizations l10n,
  Object error, {
  String? badRequest,
}) {
  if (error is! AppException) return l10n.authErrorGeneric;
  final code = error.code;
  return switch (code) {
    '401' || '403' => l10n.authErrorWrongCredentials,
    '409' => l10n.authErrorAccountExists,
    '400' => badRequest ?? l10n.authErrorCheckDetails,
    '429' => l10n.authErrorTooManyTries,
    // No answer at all: offline, or the server could not be reached.
    null || 'null' when error is NetworkException => l10n.authErrorNoConnection,
    final status? when status.startsWith('5') => l10n.authErrorServer,
    _ => l10n.authErrorGeneric,
  };
}
