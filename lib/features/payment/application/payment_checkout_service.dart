import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';

/// How one payment ended, and its reference when one was made.
class PaymentOutcome {
  final PaymentResult result;
  final String? transactionId;
  final double? amountUsd;
  final DateTime? paidAt;

  const PaymentOutcome(
    this.result, {
    this.transactionId,
    this.amountUsd,
    this.paidAt,
  });

  bool get isPaid => result == PaymentResult.paid;
}

/// What the app can pay for, start to end.
abstract interface class PaymentCheckoutService {
  /// The one-time fee that publishes listing [propertyId].
  Future<PaymentOutcome> payForListing(String propertyId, PaymentMethod method);

  /// The first month of subscription [tier] (its API name).
  Future<PaymentOutcome> payForSubscription(
    String tier,
    PaymentMethod method, {
    String? quote,
  });
}
