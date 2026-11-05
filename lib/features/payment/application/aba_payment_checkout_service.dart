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
  bool get isSimulation => false;

  @override
  Future<PaymentOutcome> payForListing(
    String propertyId,
    PaymentMethod method,
  ) async =>
      _complete(await repository.startListingCheckout(propertyId, method));

  @override
  Future<PaymentOutcome> payForSubscription(
    String tier,
    PaymentMethod method,
  ) async =>
      _complete(await repository.startSubscriptionCheckout(tier, method));

  Future<PaymentOutcome> _complete(PaymentCheckout checkout) async =>
      PaymentOutcome(
        await flow.complete(checkout),
        transactionId: checkout.transactionId,
      );
}
