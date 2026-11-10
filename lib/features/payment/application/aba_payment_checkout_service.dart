import 'package:tilomnov/features/payment/application/payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'package:tilomnov/features/payment/domain/payment_checkout.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';

/// Real payments through ABA PayWay: the server starts each checkout and
/// alone decides when it is paid.
class AbaPaymentCheckoutService implements PaymentCheckoutService {
  final PaymentRepository repository;
  final PaymentFlow flow;

  AbaPaymentCheckoutService({required this.repository, required this.flow});

  @override
  Future<PaymentOutcome> payForListing(
    String propertyId,
    PaymentMethod method,
  ) async =>
      _complete(await repository.startListingCheckout(propertyId, method));

  @override
  Future<PaymentOutcome> payForSubscription(
    String tier,
    PaymentMethod method, {
    String? quote,
  }) async => _complete(
    await repository.startSubscriptionCheckout(tier, method, quote: quote),
  );

  Future<PaymentOutcome> _complete(PaymentCheckout checkout) async {
    if (checkout.state == PaymentState.refundRequired) {
      return PaymentOutcome(
        PaymentResult.refundRequired,
        transactionId: checkout.transactionId,
      );
    }
    if (checkout.state == PaymentState.failed) {
      return PaymentOutcome(
        PaymentResult.failed,
        transactionId: checkout.transactionId,
      );
    }
    var confirmed = checkout;
    if (checkout.state != PaymentState.paid) {
      final result = await flow.complete(checkout);
      if (result != PaymentResult.paid) {
        return PaymentOutcome(result, transactionId: checkout.transactionId);
      }
      confirmed = await repository.fetchTransaction(checkout.transactionId);
      if (confirmed.state != PaymentState.paid) {
        return PaymentOutcome(
          confirmed.state == PaymentState.refundRequired
              ? PaymentResult.refundRequired
              : confirmed.state == PaymentState.failed
              ? PaymentResult.failed
              : PaymentResult.awaitingConfirmation,
          transactionId: checkout.transactionId,
        );
      }
    }
    return PaymentOutcome(
      PaymentResult.paid,
      transactionId: confirmed.transactionId,
      amountUsd: confirmed.amountUsd,
      paidAt: confirmed.paidAt,
    );
  }
}
