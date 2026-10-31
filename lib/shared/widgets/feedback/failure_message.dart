import 'package:flutter/widgets.dart';

import 'package:tilomnov/core/network/load_failure.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

/// Why something that needed the server (saving, sending, loading…) did
/// not happen, in plain words: no internet, a connection too slow, or the
/// server in trouble. Any other failure (the server refused it) is the
/// screen's own [fallback] ("Could not save your changes.").
///
/// [error] is what the repository threw, when the screen has it. Without
/// it (the layer below only said "failed"), an offline failure is still
/// told apart; see [LoadFailure.of].
String failureMessage(
  AppLocalizations l10n, {
  Object? error,
  required String fallback,
}) {
  return switch (LoadFailure.of(error)) {
    LoadFailure.offline => l10n.failureOffline,
    LoadFailure.slow => l10n.failureSlow,
    LoadFailure.server => l10n.failureServer,
    LoadFailure.other => fallback,
  };
}

/// Shows [failureMessage] as the red popup.
void showFailure(
  BuildContext context, {
  Object? error,
  required String fallback,
}) {
  if (!context.mounted) return;
  AppPopup.showError(
    context,
    failureMessage(context.l10n, error: error, fallback: fallback),
  );
}
