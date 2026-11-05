import 'dart:math';

import 'package:tilomnov/features/payment/application/payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';

/// Stands in for ABA while this build takes no payments
/// (`PAYMENTS_ENABLED` off): every payment succeeds after a short wait,
/// under a made-up reference. Nothing is charged and the server is not told.
class SimulatedPaymentCheckoutService implements PaymentCheckoutService {
  /// How long the pretend bank takes.
  final Duration delay;
  final Random _random;

  SimulatedPaymentCheckoutService({
    this.delay = const Duration(milliseconds: 1200),
    Random? random,
  }) : _random = random ?? Random();

  @override
  bool get isSimulation => true;

  @override
  Future<PaymentOutcome> payForListing(
    String propertyId,
    PaymentMethod method,
  ) => _succeed();

  @override
  Future<PaymentOutcome> payForSubscription(
    String tier,
    PaymentMethod method,
  ) => _succeed();

  Future<PaymentOutcome> _succeed() async {
    await Future<void>.delayed(delay);
    return PaymentOutcome(PaymentResult.paid, transactionId: _reference());
  }

  /// "GP" and seven digits, like `GP0001245`.
  String _reference() =>
      'GP${_random.nextInt(10000000).toString().padLeft(7, '0')}';
}
