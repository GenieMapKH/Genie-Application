import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/domain/payment_checkout.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// "$8.90": an amount in US dollars with its cents.
String formatUsd(double amount) =>
    NumberFormat.currency(locale: 'en_US', symbol: r'$').format(amount);

/// "1" or "8.90": dollars without the sign, cents only when there are some.
String formatUsdShort(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2);

/// Tells the user why a payment that did not go through is not done.
void showUnfinishedPayment(BuildContext context, PaymentResult result) {
  if (!context.mounted) return;
  final l10n = context.l10n;
  switch (result) {
    case PaymentResult.paid:
      return;
    case PaymentResult.awaitingConfirmation:
      AppPopup.showInfo(context, l10n.paymentAwaitingConfirmation);
    case PaymentResult.failed:
      AppPopup.showError(context, l10n.paymentFailed);
    case PaymentResult.notOpened:
      AppPopup.showError(context, l10n.paymentAppNotOpened);
  }
}

/// Tells the user why a payment could not start.
void showPaymentError(BuildContext context, Object error) {
  if (!context.mounted) return;
  if (error is PaymentsUnavailableException) {
    AppPopup.showInfo(context, context.l10n.paymentUnavailable);
    return;
  }
  showFailure(
    context,
    error: error,
    fallback: context.l10n.paymentCouldNotStart,
  );
}
