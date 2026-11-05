/// Whether this build charges for publishing and subscriptions.
///
/// Off unless built with `--dart-define=PAYMENTS_ENABLED=true`: the staging
/// server has no ABA PayWay merchant yet, so every checkout is simulated
/// ([SimulatedPaymentCheckoutService]): it succeeds without charging, and
/// the app does what the server would have done. Switch it on together with
/// the server's PayWay keys.
abstract final class PaymentConfig {
  static const enabled = bool.fromEnvironment('PAYMENTS_ENABLED');
}
