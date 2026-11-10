import 'package:flutter/widgets.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// Shows the saved payment; order email delivery belongs to the backend.
Future<void> showPaymentSuccess(
  BuildContext context, {
  required PaymentReceipt receipt,
  required VoidCallback onDone,
}) => context.pushPage<void>(
  PaymentSuccessPage(receipt: receipt, onDone: onDone),
);
