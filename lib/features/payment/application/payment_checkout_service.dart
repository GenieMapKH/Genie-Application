import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';

/// How one payment ended, and its reference when one was made.
class PaymentOutcome {
  final PaymentResult result;
  final String? transactionId;

  const PaymentOutcome(this.result, {this.transactionId});

  bool get isPaid => result == PaymentResult.paid;
}

/// What the app can pay for, start to end.
abstract interface class PaymentCheckoutService {
  /// True when no money moves. The server still records the purchase.
  bool get isSimulation;

  /// The one-time fee that publishes listing [propertyId].
  Future<PaymentOutcome> payForListing(String propertyId, PaymentMethod method);

  /// The first month of subscription [tier] (its API name).
  Future<PaymentOutcome> payForSubscription(String tier, PaymentMethod method);
}
