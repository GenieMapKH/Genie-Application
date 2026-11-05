import 'package:url_launcher/url_launcher.dart';

import 'package:tilomnov/features/payment/domain/payment_checkout.dart';

/// Sends the user to wherever a [PaymentCheckout] is paid.
abstract interface class PaymentAppLauncher {
  /// False when nothing could be opened.
  Future<bool> open(PaymentCheckout checkout);
}

/// ABA PayWay: ABA Mobile through its deeplink when the phone has the app,
/// else PayWay's hosted page (its KHQR can be paid with any banking app).
class AbaPaymentAppLauncher implements PaymentAppLauncher {
  const AbaPaymentAppLauncher();

  @override
  Future<bool> open(PaymentCheckout checkout) async {
    for (final target in [checkout.appDeeplink, checkout.checkoutUrl]) {
      if (target == null) continue;
      // Answers false (it does not throw) when no app takes the link.
      if (await launchUrl(target, mode: LaunchMode.externalApplication)) {
        return true;
      }
    }
    return false;
  }
}
