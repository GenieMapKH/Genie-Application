import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:tilomnov/features/payment/application/payment_app_launcher.dart';
import 'package:tilomnov/features/payment/domain/payment_checkout.dart';

/// How a payment the user went to make ended, as far as the app can tell.
enum PaymentResult {
  /// The server has the provider's confirmation.
  paid,

  /// Money arrived after the quoted upgrade period; support must refund it.
  refundRequired,

  /// The user came back but the provider has not confirmed yet. The server
  /// finishes it when the confirmation arrives.
  awaitingConfirmation,

  /// The provider declined it, or the user cancelled.
  failed,

  /// Neither the banking app nor the payment page could be opened.
  notOpened,
}

/// One payment from start to end: the server starts it, the user pays in
/// the banking app, and once they are back the server is asked how it went.
/// The app never decides that something is paid.
class PaymentFlow {
  final PaymentAppLauncher launcher;
  final Future<PaymentState> Function(String transactionId) fetchState;

  /// How often, and how long, the server is asked after the user is back.
  final Duration pollEvery;
  final Duration pollFor;

  /// Waits for the user to come back to the app; replaced in tests.
  final Future<void> Function() untilBack;

  PaymentFlow({
    required this.launcher,
    required this.fetchState,
    this.pollEvery = const Duration(seconds: 2),
    this.pollFor = const Duration(seconds: 30),
    Future<void> Function()? untilBack,
  }) : untilBack = untilBack ?? _untilResumed;

  /// Pays [checkout], which the server has just started.
  Future<PaymentResult> complete(PaymentCheckout checkout) async {
    if (!await launcher.open(checkout)) return PaymentResult.notOpened;
    await untilBack();
    return _settled(checkout.transactionId);
  }

  /// Asks until the server has an answer, or [pollFor] has passed.
  Future<PaymentResult> _settled(String transactionId) async {
    final deadline = DateTime.now().add(pollFor);
    while (true) {
      final state = await fetchState(transactionId);
      if (state == PaymentState.paid) return PaymentResult.paid;
      if (state == PaymentState.refundRequired) {
        return PaymentResult.refundRequired;
      }
      if (state == PaymentState.failed) return PaymentResult.failed;
      if (DateTime.now().isAfter(deadline)) {
        return PaymentResult.awaitingConfirmation;
      }
      await Future<void>.delayed(pollEvery);
    }
  }

  /// Completes the next time the app comes back to the foreground.
  static Future<void> _untilResumed() {
    final back = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        listener.dispose();
        if (!back.isCompleted) back.complete();
      },
    );
    return back.future;
  }
}
