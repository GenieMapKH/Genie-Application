/// How the user pays. Both go through ABA PayWay: the server turns the
/// method into PayWay's `payment_option`.
enum PaymentMethod {
  /// Opens ABA Mobile to confirm (`abapay_khqr_deeplink`). For subscriptions.
  abaPay('aba_pay'),

  /// The KHQR any Cambodian banking app can pay; opens ABA Mobile when it
  /// is installed, else PayWay's QR page. For a one-time publish.
  abaKhqr('aba_khqr');

  /// The name the server knows the method by.
  final String apiName;

  const PaymentMethod(this.apiName);
}
