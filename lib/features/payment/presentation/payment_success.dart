import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/payment/data/receipt_mailer.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// Emails the [receipt] (when the payer has an email) and shows the success
/// screen until [onDone] closes it. Completes when it is closed.
Future<void> showPaymentSuccess(
  BuildContext context,
  WidgetRef ref, {
  required PaymentReceipt receipt,
  required VoidCallback onDone,
}) {
  if (receipt.email != null) {
    unawaited(_emailReceipt(ref.read(receiptMailerProvider), receipt));
  }
  return context.pushPage<void>(
    PaymentSuccessPage(receipt: receipt, onDone: onDone),
  );
}

/// A receipt that cannot be emailed is logged; the payment itself is done.
Future<void> _emailReceipt(ReceiptMailer mailer, PaymentReceipt receipt) async {
  try {
    await mailer.send(receipt);
  } catch (e, stackTrace) {
    AppLogger.error('Emailing the receipt failed', e, stackTrace);
  }
}
