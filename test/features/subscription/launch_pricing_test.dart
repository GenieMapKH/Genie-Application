import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/publishing_allowance.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/screens/upgrade_subscription_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import '../../support/test_app.dart';

void main() {
  test(
    'launch prices, annual discounts and capacity match the pricing document',
    () {
      expect(PlanCatalog.oneTimePublishFeeUsd, 2);
      expect(
        PlanCatalog.plans.map(
          (p) => (p.monthlyPriceUsd, p.annualPriceUsd, p.listingLimit),
        ),
        [(0, 0, 1), (7, 70, 10), (15, 150, 30), (29, 290, 100)],
      );
      expect(
        const PublishingAllowance(
          tier: PlanTier.gold,
          used: 40,
          purchasedLimit: 50,
        ).hasRoom,
        isTrue,
      );
      expect(
        const PublishingAllowance(tier: PlanTier.gold, used: 30).hasRoom,
        isFalse,
      );
    },
  );

  testWidgets('annual checkout displays and pays the signed annual quote', (
    tester,
  ) async {
    final cycles = <String>[];
    final server = StubServer((request) {
      if (request.path.contains('/quote/')) {
        final annual = request.queryParameters['billingPeriod'] == 'annual';
        cycles.add(annual ? 'annual' : 'monthly');
        return (
          200,
          jsonEncode({
            'quote': annual ? 'annual-quote' : 'monthly-quote',
            'amount': annual ? 150 : 15,
            'billingPeriod': annual ? 'annual' : 'monthly',
            'periodEnd': '2027-11-10T12:00:00Z',
            'isUpgrade': false,
          }),
        );
      }
      return (
        201,
        '{"transactionId":"annual-payment","status":"Success","amount":150,"paidAt":"2026-11-10T12:00:00Z"}',
      );
    });
    await pumpTestApp(
      tester,
      UpgradeSubscriptionPage(plan: PlanCatalog.of(PlanTier.gold)),
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async =>
              UserProfile(id: 'owner', role: 'user', createdAt: DateTime(2026)),
        ),
        accountSubscriptionProvider.overrideWith((ref) async => null),
        paymentRepositoryProvider.overrideWithValue(
          PaymentRepository(server.dio),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annual · 2 months free'));
    await tester.pumpAndSettle();
    expect(cycles, contains('monthly'));
    expect(cycles.last, 'annual');
    expect(find.text(r'$150.00'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('ABA PAY').hitTestable(),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('ABA PAY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();
    final receipt = tester
        .widget<PaymentSuccessPage>(find.byType(PaymentSuccessPage))
        .receipt;
    expect(receipt.amountUsd, 150);
    final checkout = server.requests.singleWhere(
      (r) => r.path.endsWith('/checkout'),
    );
    expect(checkout.body, containsPair('quote', 'annual-quote'));
    expect(checkout.body, isNot(contains('amount')));
  });
}
