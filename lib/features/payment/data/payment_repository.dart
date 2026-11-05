import 'package:dio/dio.dart';

import 'package:tilomnov/features/payment/domain/payment_checkout.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';

/// The payment service (`/payments`). It alone talks to ABA PayWay, holds
/// the merchant keys and decides what is paid; the app only starts a
/// checkout and asks how it went. Contract: genie-backend
/// `docs/ABA_PAYWAY_INTEGRATION.md`.
class PaymentRepository {
  final Dio dio;

  PaymentRepository(this.dio);

  /// Starts paying the one-time fee that publishes listing [propertyId].
  /// The server parks the listing as Pending until the payment settles.
  Future<PaymentCheckout> startListingCheckout(
    String propertyId,
    PaymentMethod method,
  ) => _checkout('/payments/checkout', {
    'propertyId': propertyId,
    'method': method.apiName,
  });

  /// Starts paying the first month of the [tier] subscription (its API name).
  Future<PaymentCheckout> startSubscriptionCheckout(
    String tier,
    PaymentMethod method,
  ) => _checkout('/payments/subscriptions/checkout', {
    'tier': tier,
    'method': method.apiName,
  });

  /// Where transaction [transactionId] stands now.
  Future<PaymentState> fetchState(String transactionId) async {
    final response = await _guard(
      () => dio.get('/payments/transactions/$transactionId'),
    );
    final data = response.data as Map<String, dynamic>;
    return PaymentState.fromApi(data['status']);
  }

  Future<PaymentCheckout> _checkout(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _guard(() => dio.post(path, data: body));
    return PaymentCheckout.fromJson(response.data as Map<String, dynamic>);
  }

  /// A server without the endpoint (Nest's "Cannot POST …" 404) or with
  /// payments switched off (501, or `code: PAYMENTS_DISABLED`) cannot take
  /// payments yet. Any other refusal (listing not found…) is passed on.
  static Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final message = data is Map ? data['message'] : null;
      final noRoute =
          status == 404 && message is String && message.startsWith('Cannot ');
      final disabled = data is Map && data['code'] == 'PAYMENTS_DISABLED';
      if (noRoute || status == 501 || disabled) {
        throw const PaymentsUnavailableException();
      }
      rethrow;
    }
  }
}
