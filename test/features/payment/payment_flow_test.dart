import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/payment/application/payment_app_launcher.dart';
import 'package:tilomnov/features/payment/application/aba_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/simulated_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'package:tilomnov/features/payment/data/receipt_mailer.dart';
import 'package:tilomnov/features/payment/domain/payment_checkout.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';

import '../../support/test_app.dart';

class _Launcher implements PaymentAppLauncher {
  final bool opens;
  final opened = <PaymentCheckout>[];

  _Launcher({this.opens = true});

  @override
  Future<bool> open(PaymentCheckout checkout) async {
    opened.add(checkout);
    return opens;
  }
}

const _checkout = PaymentCheckout(transactionId: 't1');

PaymentFlow _flow(
  List<PaymentState> answers, {
  _Launcher? launcher,
  Duration pollFor = const Duration(seconds: 30),
}) {
  var asked = 0;
  return PaymentFlow(
    launcher: launcher ?? _Launcher(),
    fetchState: (_) async {
      final answer = answers[asked.clamp(0, answers.length - 1)];
      asked++;
      return answer;
    },
    pollEvery: Duration.zero,
    pollFor: pollFor,
    untilBack: () async {},
  );
}

void main() {
  group('PaymentFlow', () {
    test('is paid only once the server says so', () async {
      final result = await _flow([
        PaymentState.pending,
        PaymentState.pending,
        PaymentState.paid,
      ]).complete(_checkout);
      expect(result, PaymentResult.paid);
    });

    test('a declined payment fails', () async {
      final result = await _flow([PaymentState.failed]).complete(_checkout);
      expect(result, PaymentResult.failed);
    });

    test('still pending after the wait is left to the server', () async {
      final result = await _flow([
        PaymentState.pending,
      ], pollFor: Duration.zero).complete(_checkout);
      expect(result, PaymentResult.awaitingConfirmation);
    });

    test('nothing to open asks the server nothing', () async {
      var asked = false;
      final flow = PaymentFlow(
        launcher: _Launcher(opens: false),
        fetchState: (_) async {
          asked = true;
          return PaymentState.paid;
        },
        untilBack: () async {},
      );
      expect(await flow.complete(_checkout), PaymentResult.notOpened);
      expect(asked, isFalse);
    });
  });

  group('checkout services', () {
    test(
      'the simulation succeeds only after the server records the purchase',
      () async {
        final server = StubServer.always(
          201,
          '{"transactionId":"tx-mock","status":"Success","isSimulation":true}',
        );
        final service = SimulatedPaymentCheckoutService(
          repository: PaymentRepository(server.dio),
        );
        final outcome = await service.payForSubscription(
          'gold',
          PaymentMethod.abaPay,
        );
        expect(service.isSimulation, isTrue);
        expect(outcome.isPaid, isTrue);
        expect(outcome.transactionId, 'tx-mock');
        expect(server.requests.single.path, '/payments/subscriptions/checkout');
        expect(
          server.requests.single.body,
          isA<Map>().having(
            (body) => body['requestId'],
            'requestId',
            isA<String>(),
          ),
        );
      },
    );

    test('ABA starts the checkout on the server, then opens it', () async {
      final server = StubServer(
        (_) => (
          201,
          '{"transactionId":"t9","abapayDeeplink":"abamobilebank://pay?x=1",'
              '"checkoutUrl":"https://checkout.test/t9"}',
        ),
      );
      final launcher = _Launcher();
      final service = AbaPaymentCheckoutService(
        repository: PaymentRepository(server.dio),
        flow: _flow([PaymentState.paid], launcher: launcher),
      );

      final outcome = await service.payForListing('p1', PaymentMethod.abaKhqr);

      expect(service.isSimulation, isFalse);
      expect(outcome.result, PaymentResult.paid);
      expect(outcome.transactionId, 't9');
      expect(server.requests.single.path, '/payments/checkout');
      expect(server.requests.single.body, containsPair('propertyId', 'p1'));
      expect(server.requests.single.body, containsPair('method', 'aba_khqr'));
      expect(
        server.requests.single.body,
        containsPair('requestId', isA<String>()),
      );
      final opened = launcher.opened.single;
      expect(opened.appDeeplink.toString(), 'abamobilebank://pay?x=1');
      expect(opened.checkoutUrl.toString(), 'https://checkout.test/t9');
    });
  });

  test('the mock mailer writes the receipt email for the payer', () async {
    final mailer = MockReceiptMailer();
    await mailer.send(
      PaymentReceipt(
        transactionId: 'GP0001245',
        amountUsd: 1,
        item: 'One-time listing publish',
        method: PaymentMethod.abaKhqr,
        paidAt: DateTime(2026, 11, 4, 9, 30),
        email: 'hengheng168@gmail.com',
      ),
    );
    final email = mailer.sent.single;
    expect(email.to, 'hengheng168@gmail.com');
    expect(email.subject, 'Tilomnov receipt #GP0001245');
    expect(email.body, contains(r'Amount paid: $1.00'));
    expect(email.body, contains('Payment method: ABA KHQR'));
  });

  group('PaymentRepository', () {
    test('retrying a lost answer reuses the purchase reference', () async {
      var attempts = 0;
      final server = StubServer(
        (_) => ++attempts == 1
            ? (503, '{}')
            : (
                201,
                '{"transactionId":"tx-mock","status":"Success","isSimulation":true}',
              ),
      );
      final repository = PaymentRepository(server.dio);
      await expectLater(
        repository.simulateSubscription('gold', PaymentMethod.abaPay),
        throwsA(isA<Exception>()),
      );
      expect(
        await repository.simulateSubscription('gold', PaymentMethod.abaPay),
        'tx-mock',
      );
      expect(
        (server.requests[0].body as Map)['requestId'],
        (server.requests[1].body as Map)['requestId'],
      );
    });

    test(
      'a local simulation cannot succeed when the server disables it',
      () async {
        final service = SimulatedPaymentCheckoutService(
          repository: PaymentRepository(
            StubServer.always(501, '{"code":"PAYMENTS_DISABLED"}').dio,
          ),
        );
        await expectLater(
          service.payForSubscription('gold', PaymentMethod.abaPay),
          throwsA(isA<PaymentsUnavailableException>()),
        );
      },
    );
    test('a server without the endpoint cannot take payments', () async {
      final server = StubServer.always(
        404,
        '{"message":"Cannot POST /payments/subscriptions/checkout"}',
      );
      await expectLater(
        PaymentRepository(
          server.dio,
        ).startSubscriptionCheckout('gold', PaymentMethod.abaPay),
        throwsA(isA<PaymentsUnavailableException>()),
      );
    });

    test('a listing the server does not know is passed on as is', () async {
      final server = StubServer.always(404, '{"message":"Listing not found"}');
      await expectLater(
        PaymentRepository(
          server.dio,
        ).startListingCheckout('p1', PaymentMethod.abaKhqr),
        throwsA(isNot(isA<PaymentsUnavailableException>())),
      );
    });

    test('reads where a transaction stands', () async {
      final server = StubServer.always(200, '{"status":"Success"}');
      expect(
        await PaymentRepository(server.dio).fetchState('t1'),
        PaymentState.paid,
      );
      expect(server.requests.single.path, '/payments/transactions/t1');
    });
  });
}
