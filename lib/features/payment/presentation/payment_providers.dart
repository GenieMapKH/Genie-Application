import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/payment/application/aba_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_app_launcher.dart';
import 'package:tilomnov/features/payment/application/payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(apiClientProvider));
});

/// One server-owned checkout flow for every payment provider.
final paymentCheckoutServiceProvider = Provider<PaymentCheckoutService>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return AbaPaymentCheckoutService(
    repository: repository,
    flow: PaymentFlow(
      launcher: const AbaPaymentAppLauncher(),
      fetchState: repository.fetchState,
    ),
  );
});
