import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/payment/application/payment_app_launcher.dart';
import 'package:tilomnov/features/payment/application/aba_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'package:tilomnov/features/payment/domain/payment_checkout.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';

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
  testWidgets(
    'a refund message includes the transaction reference for support',
    (tester) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showUnfinishedPayment(
                context,
                PaymentResult.refundRequired,
                transactionId: 'late-upgrade-123',
              ),
              child: const Text('show'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Please contact support'), findsOneWidget);
      expect(find.textContaining('late-upgrade-123'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );
  group('PaymentFlow', () {
    test('a late upgrade stops polling and requires a refund', () async {
      expect(
        PaymentState.fromApi('RefundRequired'),
        PaymentState.refundRequired,
      );
      final result = await _flow([
        PaymentState.refundRequired,
      ]).complete(_checkout);
      expect(result, PaymentResult.refundRequired);
    });
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
    test('a late upgrade never opens the bank or reports success', () async {
      final server = StubServer.always(
        201,
        '{"transactionId":"late","status":"RefundRequired"}',
      );
      final launcher = _Launcher();
      final service = AbaPaymentCheckoutService(
        repository: PaymentRepository(server.dio),
        flow: _flow([PaymentState.paid], launcher: launcher),
      );
      final outcome = await service.payForSubscription(
        'diamond',
        PaymentMethod.abaPay,
      );
      expect(outcome.isPaid, isFalse);
      expect(outcome.result, PaymentResult.refundRequired);
      expect(outcome.transactionId, 'late');
      expect(launcher.opened, isEmpty);
    });
    test(
      'a completed server checkout needs no banking app, regardless of provider',
      () async {
        final server = StubServer.always(
          201,
          '{"transactionId":"tx-mock","status":"Success","amount":8.9,"paidAt":"2026-11-08T00:00:00.000Z"}',
        );
        final service = AbaPaymentCheckoutService(
          repository: PaymentRepository(server.dio),
          flow: _flow([PaymentState.paid]),
        );
        final outcome = await service.payForSubscription(
          'gold',
          PaymentMethod.abaPay,
        );
        expect(outcome.isPaid, isTrue);
        expect(outcome.transactionId, 'tx-mock');
        expect(server.requests.single.path, '/payments/subscriptions/checkout');
        expect(
          server.requests.first.body,
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
        (request) => request.method == 'GET'
            ? (
                200,
                '{"transactionId":"t9","status":"Success","amount":1,"paidAt":"2026-11-08T00:00:00.000Z"}',
              )
            : (
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

      expect(outcome.result, PaymentResult.paid);
      expect(outcome.transactionId, 't9');
      expect(server.requests.first.path, '/payments/checkout');
      expect(server.requests.first.body, containsPair('propertyId', 'p1'));
      expect(server.requests.first.body, containsPair('method', 'aba_khqr'));
      expect(
        server.requests.first.body,
        containsPair('requestId', isA<String>()),
      );
      final opened = launcher.opened.single;
      expect(opened.appDeeplink.toString(), 'abamobilebank://pay?x=1');
      expect(opened.checkoutUrl.toString(), 'https://checkout.test/t9');
    });
  });

  group('PaymentRepository', () {
    test('retrying a lost answer reuses the purchase reference', () async {
      var attempts = 0;
      final server = StubServer(
        (_) => ++attempts == 1
            ? (503, '{}')
            : (
                201,
                '{"transactionId":"tx-mock","status":"Success","amount":8.9,"paidAt":"2026-11-08T00:00:00.000Z"}',
              ),
      );
      final repository = PaymentRepository(server.dio);
      await expectLater(
        repository.startSubscriptionCheckout('gold', PaymentMethod.abaPay),
        throwsA(isA<Exception>()),
      );
      expect(
        (await repository.startSubscriptionCheckout(
          'gold',
          PaymentMethod.abaPay,
        )).transactionId,
        'tx-mock',
      );
      expect(
        (server.requests[0].body as Map)['requestId'],
        (server.requests[1].body as Map)['requestId'],
      );
    });

    test('checkout cannot succeed when the server disables it', () async {
      final service = AbaPaymentCheckoutService(
        repository: PaymentRepository(
          StubServer.always(501, '{"code":"PAYMENTS_DISABLED"}').dio,
        ),
        flow: _flow([PaymentState.paid]),
      );
      await expectLater(
        service.payForSubscription('gold', PaymentMethod.abaPay),
        throwsA(isA<PaymentsUnavailableException>()),
      );
    });
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

    test(
      'a pending checkout retains its reference until it is settled',
      () async {
        final server = StubServer.always(
          201,
          '{"transactionId":"pending-1","status":"Pending","checkoutUrl":"https://bank.test/pay"}',
        );
        final repository = PaymentRepository(server.dio);
        await repository.startSubscriptionCheckout(
          'gold',
          PaymentMethod.abaPay,
        );
        await repository.startSubscriptionCheckout(
          'gold',
          PaymentMethod.abaPay,
        );
        expect(
          (server.requests[0].body as Map)['requestId'],
          (server.requests[1].body as Map)['requestId'],
        );
      },
    );

    test('reads where a transaction stands', () async {
      final server = StubServer.always(
        200,
        '{"transactionId":"t1","status":"Success"}',
      );
      expect(
        await PaymentRepository(server.dio).fetchState('t1'),
        PaymentState.paid,
      );
      expect(server.requests.single.path, '/payments/transactions/t1');
    });
  });
}
