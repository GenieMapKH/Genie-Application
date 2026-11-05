import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/payment/application/simulated_payment_checkout_service.dart';
import 'package:tilomnov/features/payment/data/receipt_mailer.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/publishing_allowance.dart';
import 'package:tilomnov/features/subscription/presentation/screens/subscription_plans_page.dart';
import 'package:tilomnov/features/subscription/presentation/screens/upgrade_subscription_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';

import '../../support/test_app.dart';

final _payer = UserProfile(
  id: 'u1',
  email: 'hengheng168@gmail.com',
  role: 'user',
  createdAt: DateTime(2026),
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

  testWidgets('every plan is listed, with upgrades only above the current', (
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
    expect(find.text('Upgrade to Free'), findsNothing);
    expect(find.text('Upgrade to Silver'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Upgrade to Diamond'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Upgrade to Gold'), findsOneWidget);
    expect(find.text('Upgrade to Diamond'), findsOneWidget);
  });

  testWidgets(
    'Subscribe, once a method is picked, pays and shows the success screen',
    (tester) async {
      final mailer = MockReceiptMailer();
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
          paymentCheckoutServiceProvider.overrideWithValue(
            SimulatedPaymentCheckoutService(delay: Duration.zero),
          ),
          receiptMailerProvider.overrideWithValue(mailer),
        ],
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Upgrade to Gold'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Upgrade to Gold'));
      await tester.pumpAndSettle();
      expect(find.byType(UpgradeSubscriptionPage), findsOneWidget);
      expect(find.text(r'$8.90'), findsWidgets);
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
      expect(find.text('8.90 USD'), findsOneWidget);
      expect(find.textContaining('Transaction ID  #GP'), findsOneWidget);
      expect(find.textContaining('hengheng168@gmail.com'), findsWidgets);
      expect(mailer.sent.single.to, 'hengheng168@gmail.com');
      expect(mailer.sent.single.body, contains('Gold plan'));

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentSuccessPage), findsNothing);
      expect(find.byType(SubscriptionPlansPage), findsNothing);
      expect(find.text('tier: gold'), findsOneWidget);
    },
  );
}
