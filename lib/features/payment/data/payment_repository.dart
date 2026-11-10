import 'package:dio/dio.dart';
import 'dart:math';

import 'package:tilomnov/features/payment/domain/payment_checkout.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/subscription/domain/account_subscription.dart';
import 'package:tilomnov/features/subscription/domain/subscription_quote.dart';
import 'package:tilomnov/core/network/api_cache_manager.dart';

/// The payment service (`/payments`). It alone talks to ABA PayWay, holds
/// the merchant keys and decides what is paid; the app only starts a
/// checkout and asks how it went. Contract: genie-backend
/// `docs/ABA_PAYWAY_INTEGRATION.md`.
class PaymentRepository {
  final Dio dio;
  final _requestIds = <String, String>{};

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
    PaymentMethod method, {
    String? quote,
  }) => _checkout('/payments/subscriptions/checkout', {
    'tier': tier,
    'method': method.apiName,
    'quote': ?quote,
  });

  /// Where transaction [transactionId] stands now.
  Future<PaymentState> fetchState(String transactionId) async =>
      (await fetchTransaction(transactionId)).state;

  Future<PaymentCheckout> fetchTransaction(String transactionId) async {
    final response = await _guard(
      () => dio.get(
        '/payments/transactions/$transactionId',
        options: Options(extra: {CacheInterceptor.skipCache: true}),
      ),
    );
    final data = response.data as Map<String, dynamic>;
    return PaymentCheckout.fromJson(data);
  }

  Future<PaymentCheckout> _checkout(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _sendCheckout(path, body);
    return PaymentCheckout.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubscriptionQuote> subscriptionQuote(
    String tier, {
    String billingPeriod = 'monthly',
  }) async {
    final response = await _guard(
      () => dio.get(
        '/payments/subscriptions/quote/$tier',
        queryParameters: {'billingPeriod': billingPeriod},
        options: Options(extra: {CacheInterceptor.skipCache: true}),
      ),
    );
    return SubscriptionQuote.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Response<dynamic>> _sendCheckout(
    String path,
    Map<String, dynamic> body,
  ) async {
    // shortcut: retry references live in memory; persist pending checkout recovery before live bank payments.
    final intent =
        '$path:${body['propertyId'] ?? body['tier']}:${body['quote'] ?? ''}';
    final requestId = _requestIds.putIfAbsent(intent, () {
      final random = Random.secure();
      final bytes = List.generate(16, (_) => random.nextInt(256));
      bytes[6] = (bytes[6] & 15) | 64;
      bytes[8] = (bytes[8] & 63) | 128;
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    });
    final response = await _guard(
      () => dio.post(path, data: {...body, 'requestId': requestId}),
    );
    final data = response.data;
    if (data is Map &&
        ['Success', 'Failed', 'RefundRequired'].contains(data['status'])) {
      _requestIds.remove(intent);
    }
    return response;
  }

  Future<AccountSubscription?> fetchSubscription() async {
    final response = await dio.get(
      '/payments/subscriptions/current',
      options: Options(extra: {CacheInterceptor.skipCache: true}),
    );
    return _subscription(response.data as Map<String, dynamic>);
  }

  Future<AccountSubscription?> cancelSubscription() async {
    final response = await dio.post('/payments/subscriptions/cancel');
    return _subscription(response.data as Map<String, dynamic>);
  }

  Future<AccountSubscription?> fetchExpiredSubscription() async {
    final response = await dio.get(
      '/payments/subscriptions/expired',
      options: Options(extra: {CacheInterceptor.skipCache: true}),
    );
    return _subscription(response.data as Map<String, dynamic>);
  }

  static AccountSubscription? _subscription(Map<String, dynamic> data) {
    final json = data['subscription'];
    return json == null
        ? null
        : AccountSubscription.fromJson(json as Map<String, dynamic>);
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
