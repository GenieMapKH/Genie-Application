import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/payment/application/simulated_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/data/receipt_mailer.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'dart:convert';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/domain/publishing_allowance.dart';
import 'package:tilomnov/features/subscription/presentation/screens/subscription_plans_page.dart';
import 'package:tilomnov/features/subscription/presentation/screens/upgrade_subscription_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/plan_card.dart';

import '../../support/test_app.dart';

final _payer = UserProfile(
  id: 'u1',
  email: 'hengheng168@gmail.com',
  role: 'user',
  createdAt: DateTime(2026),
);

Finder _subscribeTo(PlanTier tier) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is PlanCard && widget.plan.tier == tier,
  ),
  matching: find.text('Subscribe'),
);

void main() {
  group('plans', () {
    test('a tier the server names is read whatever its case', () {
      expect(PlanTier.fromApi('GOLD'), PlanTier.gold);
      expect(PlanTier.fromApi('platinum'), PlanTier.free);
      expect(PlanTier.fromApi(null), PlanTier.free);
    });

    test('the profile carries the tier from subscription.tier', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'role': 'user',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'subscription': {'tier': 'diamond'},
      });
      expect(profile.subscriptionTier, 'diamond');
    });

    test('a full plan has no room for one more listing', () {
      expect(
        const PublishingAllowance(tier: PlanTier.free, used: 0).hasRoom,
        isTrue,
      );
      expect(
        const PublishingAllowance(tier: PlanTier.free, used: 1).hasRoom,
        isFalse,
      );
      expect(
        const PublishingAllowance(tier: PlanTier.gold, used: 49).hasRoom,
        isTrue,
      );
    });
  });

  testWidgets('simulation offers every paid plan, including the current', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const SubscriptionPlansPage(),
      overrides: [
        currentPlanTierProvider.overrideWithValue(PlanTier.silver),
        publishingAllowanceProvider.overrideWith(
          (ref) async =>
              const PublishingAllowance(tier: PlanTier.silver, used: 4),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Current Plan'), findsOneWidget);
    expect(find.text('4 / 20 listings used'), findsOneWidget);
    expect(_subscribeTo(PlanTier.free), findsNothing);
    expect(_subscribeTo(PlanTier.silver), findsOneWidget);
    await tester.scrollUntilVisible(
      _subscribeTo(PlanTier.diamond),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(_subscribeTo(PlanTier.gold), findsOneWidget);
    expect(_subscribeTo(PlanTier.diamond), findsOneWidget);
  });

  for (final tier in [PlanTier.silver, PlanTier.gold, PlanTier.diamond]) {
    testWidgets(
      'simulated ${tier.name} purchase from Gold shows success and receipt',
      (tester) async {
        final amount = PlanCatalog.of(tier).monthlyPriceUsd.toStringAsFixed(2);
        final mailer = MockReceiptMailer();
        var bought = false;
        final server = StubServer((request) {
          if (request.path.endsWith('/checkout')) {
            bought = true;
            return (
              201,
              '{"transactionId":"tx-mock","status":"Success","isSimulation":true}',
            );
          }
          return (
            200,
            jsonEncode({
              'subscription': {
                'tier': bought ? tier.name : 'gold',
                'currentPeriodStart': DateTime.now().toUtc().toIso8601String(),
                'currentPeriodEnd': DateTime.now()
                    .add(const Duration(days: 30))
                    .toUtc()
                    .toIso8601String(),
                'cancelAtPeriodEnd': false,
              },
            }),
          );
        });
        final repository = PaymentRepository(server.dio);
        // A phone screen, so the payment method sits above Subscribe.
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await pumpTestApp(
          tester,
          Consumer(
            builder: (context, ref, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('tier: ${ref.watch(currentPlanTierProvider).name}'),
                TextButton(
                  onPressed: () =>
                      context.pushPage(const SubscriptionPlansPage()),
                  child: const Text('open'),
                ),
              ],
            ),
          ),
          overrides: [
            userProfileProvider.overrideWith((ref) async => _payer),
            paymentRepositoryProvider.overrideWithValue(repository),
            paymentCheckoutServiceProvider.overrideWithValue(
              SimulatedPaymentCheckoutService(repository: repository),
            ),
            receiptMailerProvider.overrideWithValue(mailer),
          ],
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          _subscribeTo(tier).hitTestable(),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(_subscribeTo(tier));
        await tester.pumpAndSettle();
        expect(find.byType(UpgradeSubscriptionPage), findsOneWidget);
        expect(find.text('\$$amount'), findsWidgets);
        expect(find.text('Monthly'), findsOneWidget);

        // Nothing picked: the button does nothing.
        await tester.tap(find.text('Subscribe'));
        await tester.pumpAndSettle();
        expect(find.byType(PaymentSuccessPage), findsNothing);

        await tester.tap(find.text('ABA PAY'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Subscribe'));
        await tester.pumpAndSettle();

        expect(find.byType(PaymentSuccessPage), findsOneWidget);
        expect(find.text('Success'), findsOneWidget);
        expect(find.text('$amount USD'), findsOneWidget);
        expect(find.textContaining('Transaction ID  #tx-mock'), findsOneWidget);
        expect(find.textContaining('hengheng168@gmail.com'), findsWidgets);
        expect(mailer.sent.single.to, 'hengheng168@gmail.com');
        expect(mailer.sent.single.body, contains(amount));
        expect(find.text('Download Receipt'), findsOneWidget);
        expect(
          server.requests.singleWhere((r) => r.path.endsWith('/checkout')).body,
          containsPair('tier', tier.name),
        );

        await tester.tap(find.text('Back to Home'));
        await tester.pumpAndSettle();
        expect(find.byType(PaymentSuccessPage), findsNothing);
        expect(find.byType(SubscriptionPlansPage), findsNothing);
        expect(find.text('tier: ${tier.name}'), findsOneWidget);
      },
    );
  }

  testWidgets('cancel turns renewal off, keeps Gold and survives reopening', (
    tester,
  ) async {
    var cancelled = false;
    final end = DateTime.now().add(const Duration(days: 30));
    final server = StubServer((request) {
      if (request.path.endsWith('/cancel')) cancelled = true;
      return (
        200,
        jsonEncode({
          'subscription': {
            'tier': 'gold',
            'currentPeriodStart': DateTime.now().toUtc().toIso8601String(),
            'currentPeriodEnd': end.toUtc().toIso8601String(),
            'cancelAtPeriodEnd': cancelled,
          },
        }),
      );
    });
    final repository = PaymentRepository(server.dio);
    Future<void> open() => pumpTestApp(
      tester,
      const SubscriptionPlansPage(),
      overrides: [
        userProfileProvider.overrideWith((ref) async => _payer),
        paymentRepositoryProvider.overrideWithValue(repository),
        publishingAllowanceProvider.overrideWith(
          (ref) async =>
              const PublishingAllowance(tier: PlanTier.gold, used: 2),
        ),
      ],
    );
    await open();
    await tester.pumpAndSettle();
    expect(find.text('Cancel plan'), findsOneWidget);
    await tester.tap(find.text('Cancel plan'));
    await tester.pumpAndSettle();
    expect(find.text('Turn off automatic renewal?'), findsOneWidget);
    await tester.tap(find.text('Cancel plan').last);
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
    expect(find.text('Cancel plan'), findsNothing);
    expect(find.textContaining('Automatic renewal is off.'), findsOneWidget);
    var container = ProviderScope.containerOf(
      tester.element(find.byType(SubscriptionPlansPage)),
    );
    expect(container.read(currentPlanTierProvider), PlanTier.gold);
    expect(
      container.read(accountSubscriptionProvider).valueOrNull?.expiresAt,
      end.toUtc(),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await open();
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(SubscriptionPlansPage)),
    );
    expect(container.read(currentPlanTierProvider), PlanTier.gold);
    expect(find.text('Cancel plan'), findsNothing);
    expect(find.textContaining('Automatic renewal is off.'), findsOneWidget);
  });
}
