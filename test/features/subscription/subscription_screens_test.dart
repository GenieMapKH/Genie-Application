import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'dart:convert';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/account_subscription.dart';
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
  matching: find.text(
    'Upgrade to ${tier.name[0].toUpperCase()}${tier.name.substring(1)}',
  ),
);

void main() {
  group('plans', () {
    test(
      'usage reads the server plan count, excluding one-time paid posts',
      () async {
        final server = StubServer.always(200, '{"used":1}');
        final container = ProviderContainer(
          overrides: [
            signedInOverride(),
            accountSubscriptionProvider.overrideWith((ref) async => null),
            propertyRepositoryProvider.overrideWithValue(
              PropertyRepository(server.dio),
            ),
          ],
        );
        addTearDown(container.dispose);
        final allowance = await container.read(
          publishingAllowanceProvider.future,
        );
        expect(allowance.tier, PlanTier.free);
        expect(allowance.used, 1);
        expect(allowance.hasRoom, isFalse);
        expect(server.requests.single.path, '/properties/my/publishing-usage');
      },
    );

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
        const PublishingAllowance(tier: PlanTier.gold, used: 29).hasRoom,
        isTrue,
      );
    });
  });

  testWidgets(
    'Gold shows Current Plan without offering the same subscription',
    (tester) async {
      await pumpTestApp(
        tester,
        const SubscriptionPlansPage(),
        overrides: [
          currentPlanTierProvider.overrideWithValue(PlanTier.gold),
          publishingAllowanceProvider.overrideWith(
            (ref) async =>
                const PublishingAllowance(tier: PlanTier.gold, used: 4),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Current Plan'), findsOneWidget);
      expect(find.text('4 / 30 listings used'), findsOneWidget);
      expect(_subscribeTo(PlanTier.free), findsNothing);
      expect(_subscribeTo(PlanTier.silver), findsNothing);
      expect(_subscribeTo(PlanTier.gold), findsNothing);
      await tester.scrollUntilVisible(
        _subscribeTo(PlanTier.diamond),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_subscribeTo(PlanTier.gold), findsNothing);
      expect(_subscribeTo(PlanTier.diamond), findsOneWidget);
    },
  );

  for (final tier in [PlanTier.silver, PlanTier.gold, PlanTier.diamond]) {
    testWidgets('${tier.name} purchase follows the common checkout flow', (
      tester,
    ) async {
      final amount = PlanCatalog.of(tier).monthlyPriceUsd.toStringAsFixed(2);
      var bought = false;
      final server = StubServer((request) {
        if (request.path.contains('/quote/')) {
          return (
            200,
            jsonEncode({
              'quote': 'signed-quote',
              'amount': double.parse(amount),
              'periodEnd': DateTime.now()
                  .add(const Duration(days: 30))
                  .toUtc()
                  .toIso8601String(),
              'isUpgrade': false,
            }),
          );
        }
        if (request.path.endsWith('/checkout')) {
          bought = true;
          return (
            201,
            jsonEncode({
              'transactionId': 'tx-mock',
              'status': 'Success',
              'amount': double.parse(amount),
              'paidAt': DateTime.now().toUtc().toIso8601String(),
            }),
          );
        }
        return (
          200,
          jsonEncode({
            'subscription': bought
                ? {
                    'tier': tier.name,
                    'currentPeriodStart': DateTime.now()
                        .toUtc()
                        .toIso8601String(),
                    'currentPeriodEnd': DateTime.now()
                        .add(const Duration(days: 30))
                        .toUtc()
                        .toIso8601String(),
                    'cancelAtPeriodEnd': false,
                  }
                : null,
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
      expect(find.text('Monthly'), findsWidgets);

      // Nothing picked: the button does nothing.
      await tester.tap(find.text('Subscribe'));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentSuccessPage), findsNothing);

      await tester.scrollUntilVisible(
        find.text('ABA PAY').hitTestable(),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABA PAY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Subscribe'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentSuccessPage), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('${double.parse(amount).toInt()} USD'), findsOneWidget);
      expect(find.textContaining('Transaction ID  #tx-mock'), findsOneWidget);
      expect(find.textContaining('hengheng168@gmail.com'), findsWidgets);
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
    });
  }

  testWidgets('Gold to Diamond displays and pays the server prorated quote', (
    tester,
  ) async {
    final expiry = DateTime.now().add(const Duration(days: 15)).toUtc();
    final paidAt = DateTime.now().toUtc();
    final server = StubServer(
      (request) => request.path.contains('/quote/')
          ? (
              200,
              jsonEncode({
                'quote': 'exact-price-token',
                'amount': 4,
                'periodEnd': expiry.toIso8601String(),
                'isUpgrade': true,
              }),
            )
          : (
              201,
              jsonEncode({
                'transactionId': 'upgrade-1',
                'status': 'Success',
                'amount': 4,
                'paidAt': paidAt.toIso8601String(),
              }),
            ),
    );
    await pumpTestApp(
      tester,
      UpgradeSubscriptionPage(plan: PlanCatalog.of(PlanTier.diamond)),
      overrides: [
        userProfileProvider.overrideWith((ref) async => _payer),
        currentPlanTierProvider.overrideWithValue(PlanTier.gold),
        accountSubscriptionProvider.overrideWith(
          (ref) async => AccountSubscription(
            tier: PlanTier.gold,
            startsAt: expiry.subtract(const Duration(days: 30)),
            expiresAt: expiry,
            cancelAtPeriodEnd: false,
          ),
        ),
        paymentRepositoryProvider.overrideWithValue(
          PaymentRepository(server.dio),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(r'$4.00'), findsWidgets);
    expect(find.textContaining('Test purchase'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('ABA PAY'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('ABA PAY').hitTestable(),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABA PAY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentSuccessPage), findsOneWidget);
    expect(
      tester
          .widget<PaymentSuccessPage>(find.byType(PaymentSuccessPage))
          .receipt
          .amountUsd,
      4,
    );
    final checkout = server.requests.singleWhere(
      (r) => r.path.endsWith('/checkout'),
    );
    expect(checkout.body, containsPair('quote', 'exact-price-token'));
    expect(checkout.body, isNot(contains('amount')));
  });

  testWidgets('a failed price quote cannot start payment', (tester) async {
    final server = StubServer.always(503, '{}');
    await pumpTestApp(
      tester,
      UpgradeSubscriptionPage(plan: PlanCatalog.of(PlanTier.gold)),
      overrides: [
        currentPlanTierProvider.overrideWithValue(PlanTier.free),
        accountSubscriptionProvider.overrideWith((ref) async => null),
        paymentRepositoryProvider.overrideWithValue(
          PaymentRepository(server.dio),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('ABA PAY'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('ABA PAY').hitTestable(),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABA PAY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    expect(server.requests.where((r) => r.path.endsWith('/checkout')), isEmpty);
    expect(find.byType(PaymentSuccessPage), findsNothing);
  });

  testWidgets('opening checkout for active Gold cannot subscribe again', (
    tester,
  ) async {
    final server = StubServer.always(500, '{}');
    await pumpTestApp(
      tester,
      UpgradeSubscriptionPage(plan: PlanCatalog.of(PlanTier.gold)),
      overrides: [
        currentPlanTierProvider.overrideWithValue(PlanTier.gold),
        paymentRepositoryProvider.overrideWithValue(
          PaymentRepository(server.dio),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('ABA PAY'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('ABA PAY').hitTestable(),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABA PAY'));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe'), findsNothing);
    await tester.tap(find.text('Current Plan').last);
    await tester.pumpAndSettle();
    expect(server.requests.where((r) => r.path.endsWith('/checkout')), isEmpty);
    expect(find.byType(PaymentSuccessPage), findsNothing);
  });

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
    await tester.scrollUntilVisible(
      find.text('Cancel plan').hitTestable(),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final goldCard = find.byWidgetPredicate(
      (widget) => widget is PlanCard && widget.plan.tier == PlanTier.gold,
    );
    expect(
      find.descendant(of: goldCard, matching: find.text('Cancel plan')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: goldCard,
        matching: find.textContaining('Plan active until'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.textContaining('Plan active until'))
          .style
          ?.color,
      Colors.white,
    );
    await tester.tap(find.text('Cancel plan'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel your plan?'), findsOneWidget);
    await tester.tap(find.text('Cancel plan').last);
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
    expect(
      find.descendant(
        of: goldCard,
        matching: find.textContaining('Plan cancelled.'),
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel plan'), findsNothing);
    expect(find.textContaining('Plan cancelled.'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.textContaining('Plan cancelled.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(SubscriptionPlansPage)),
    );
    expect(container.read(currentPlanTierProvider), PlanTier.gold);
    expect(find.text('Cancel plan'), findsNothing);
    expect(find.textContaining('Plan cancelled.'), findsOneWidget);
  });
}
