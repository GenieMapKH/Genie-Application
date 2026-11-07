import 'package:tilomnov/features/payment/application/payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';

/// No money moves. The server must explicitly enable mock payments and stores
/// the transaction and entitlement before this reports success.
class SimulatedPaymentCheckoutService implements PaymentCheckoutService {
  final PaymentRepository repository;

  SimulatedPaymentCheckoutService({required this.repository});

  @override
  bool get isSimulation => true;

  @override
  Future<PaymentOutcome> payForListing(
    String propertyId,
    PaymentMethod method,
  ) async => PaymentOutcome(
    PaymentResult.paid,
    transactionId: await repository.simulateListing(propertyId, method),
  );

  @override
  Future<PaymentOutcome> payForSubscription(
    String tier,
    PaymentMethod method,
  ) async => PaymentOutcome(
    PaymentResult.paid,
    transactionId: await repository.simulateSubscription(tier, method),
  );
}
