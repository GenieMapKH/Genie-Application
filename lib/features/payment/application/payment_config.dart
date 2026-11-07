/// Whether this build charges for publishing and subscriptions.
///
/// Off unless built with `--dart-define=PAYMENTS_ENABLED=true`: the
/// server has no ABA PayWay merchant yet, so every checkout is simulated
/// ([SimulatedPaymentCheckoutService]), including production app builds.
/// The server defaults to mock mode and persists purchases without charging.
/// Switch on real payments only
/// after the server's PayWay integration is complete and verified.
abstract final class PaymentConfig {
  static const enabled = bool.fromEnvironment('PAYMENTS_ENABLED');
}
