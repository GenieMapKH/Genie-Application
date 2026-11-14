/// A payment the server has started with the provider: where to send the
/// user to pay it, and the id to ask about it afterwards.
class PaymentCheckout {
  final String transactionId;
  final PaymentState state;
  final double? amountUsd;
  final bool isSimulation;
  final DateTime? paidAt;

  /// Opens ABA Mobile straight on the payment. Null when the provider gave
  /// none; [checkoutUrl] is then the way to pay.
  final Uri? appDeeplink;

  /// The provider's hosted payment page (card or KHQR), in a browser.
  final Uri? checkoutUrl;

  const PaymentCheckout({
    required this.transactionId,
    this.state = PaymentState.pending,
    this.amountUsd,
    this.paidAt,
    this.isSimulation = false,
    this.appDeeplink,
    this.checkoutUrl,
  });

  factory PaymentCheckout.fromJson(Map<String, dynamic> json) {
    Uri? uri(Object? value) =>
        value is String && value.isNotEmpty ? Uri.tryParse(value) : null;
    return PaymentCheckout(
      transactionId: json['transactionId'] as String,
      isSimulation: json['isSimulation'] == true,
      state: PaymentState.fromApi(json['status']),
      amountUsd: (json['amount'] as num?)?.toDouble(),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      appDeeplink: uri(json['abapayDeeplink']),
      checkoutUrl: uri(json['checkoutUrl']),
    );
  }
}

/// Where a payment stands, as the server knows it. The server only marks a
/// payment paid after the provider confirmed it, never because the app
/// came back from the banking app.
enum PaymentState {
  pending,
  paid,
  refundRequired,
  failed;

  static PaymentState fromApi(Object? value) => switch (value) {
    'Success' => paid,
    'RefundRequired' => refundRequired,
    'Failed' => failed,
    _ => pending,
  };
}

/// The server cannot take payments: the endpoint does not exist yet
/// (staging) or payments are switched off.
class PaymentsUnavailableException implements Exception {
  const PaymentsUnavailableException();

  @override
  String toString() => 'PaymentsUnavailableException';
}
