import 'package:flutter/material.dart';

import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

/// After a pull-to-refresh of a screen that keeps showing what it had: when
/// there is no internet, the red "No internet connection" with a retry
/// button ([onRetry]), since what is shown is from before; when the server
/// could not be read for another reason, [failedMessage]. Nothing when it
/// worked.
void showRefreshOutcome(
  BuildContext context, {
  required bool ok,
  required String failedMessage,
  required VoidCallback onRetry,
}) {
  if (!context.mounted) return;
  if (NetworkStatus.instance.isOffline) {
    AppPopup.showOffline(
      context,
      context.l10n.connectionOffline,
      onRetry: onRetry,
    );
  } else if (!ok) {
    AppPopup.showError(context, failedMessage);
  }
}
