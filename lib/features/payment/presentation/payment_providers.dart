import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/payment/application/aba_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_app_launcher.dart';
import 'package:tilomnov/features/payment/application/payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_config.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/application/simulated_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'package:tilomnov/features/payment/data/receipt_mailer.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});

/// ABA PayWay when this build takes payments, else the simulation.
final paymentCheckoutServiceProvider = Provider<PaymentCheckoutService>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  if (!PaymentConfig.enabled) {
    return SimulatedPaymentCheckoutService(repository: repository);
  }
  return AbaPaymentCheckoutService(
    repository: repository,
    flow: PaymentFlow(
      launcher: const AbaPaymentAppLauncher(),
      fetchState: repository.fetchState,
    ),
  );
});

/// Receipts are only written to the log until the server sends them.
final receiptMailerProvider = Provider<ReceiptMailer>(
  (ref) => MockReceiptMailer(),
);
