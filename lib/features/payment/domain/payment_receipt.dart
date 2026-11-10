import 'payment_method.dart';

/// Proof of one completed payment: what the success screen, the saved
/// receipt picture and the receipt email show.
class PaymentReceipt {
  /// The reference the user quotes, without the "#" (e.g. `GP0001245`).
  final String transactionId;

  /// US dollars, tax included.
  final double amountUsd;

  /// What was bought, in the user's language ("Gold plan · Monthly").
  final String item;
  final PaymentMethod method;
  final DateTime paidAt;

  /// Where the receipt is emailed; null for an account without an email.
  final String? email;

  const PaymentReceipt({
    required this.transactionId,
    required this.amountUsd,
    required this.item,
    required this.method,
    required this.paidAt,
    this.email,
  });
}
