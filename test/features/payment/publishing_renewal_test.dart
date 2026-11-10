import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/payment/application/payment_checkout_service.dart';
import 'package:tilomnov/features/payment/application/payment_flow.dart';
import 'package:tilomnov/features/payment/data/payment_repository.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/renewal_checkout.dart';
import 'package:tilomnov/features/payment/presentation/screens/one_time_payment_page.dart';
import 'package:tilomnov/features/payment/presentation/screens/payment_success_page.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/actions/property_visibility_sheet.dart';
import 'package:tilomnov/features/subscription/domain/account_subscription.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/presentation/screens/upgrade_subscription_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/expired_subscription_alert.dart';
import '../../support/test_app.dart';

class _Checkout implements PaymentCheckoutService {
  final calls = <String>[];
  @override
  Future<PaymentOutcome> payForListing(String id, PaymentMethod method) async {
    calls.add(id);
    return const PaymentOutcome(
      PaymentResult.paid,
      transactionId: 'listing-renewal',
      amountUsd: 1,
    );
  }

  @override
  Future<PaymentOutcome> payForSubscription(
    String tier,
    PaymentMethod method, {
    String? quote,
  }) async {
    calls.add(tier);
    return const PaymentOutcome(
      PaymentResult.paid,
      transactionId: 'subscription-renewal',
      amountUsd: 8.9,
    );
  }
}

final _user = UserProfile(
  id: 'u1',
  role: 'user',
  email: 'owner@example.test',
  createdAt: DateTime(2026),
);
final _property = PropertyModel(
  id: 'p1',
  title: 'Riverside plot',
  price: '1000',
  propertyType: 'Land',
  status: 'Draft',
  createdAt: DateTime(2026),
);

void main() {
  testWidgets(
    'property renewal pays once and closes the shared checkout after its receipt',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final checkout = _Checkout();
      bool? renewed;
      await pumpTestApp(
        tester,
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async =>
                  renewed = await renewProperty(context, ref, _property),
              child: const Text('Renew post'),
            ),
          ),
        ),
        overrides: [
          userProfileProvider.overrideWith((ref) async => _user),
          paymentCheckoutServiceProvider.overrideWithValue(checkout),
        ],
      );
      await tester.tap(find.text('Renew post'));
      await tester.pumpAndSettle();
      expect(find.text('Renew property post'), findsOneWidget);
      expect(checkout.calls, isEmpty);
      await tester.ensureVisible(find.text('ABA KHQR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABA KHQR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish Property'));
      await tester.pumpAndSettle();
      expect(checkout.calls, ['p1']);
      expect(find.byType(PaymentSuccessPage), findsOneWidget);
      await tester.ensureVisible(find.text('Back to Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(renewed, isTrue);
      expect(find.byType(OneTimePaymentPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelling the renewal keeps the visibility sheet open without claiming activation',
    (tester) async {
      bool? saved;
      await pumpTestApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await PropertyVisibilitySheet.show(
                  context,
                  'Draft',
                  onChanged: (_) async => throw DioException(
                    requestOptions: RequestOptions(path: '/publish'),
                    response: Response(
                      requestOptions: RequestOptions(path: '/publish'),
                      statusCode: 402,
                    ),
                  ),
                  onPaymentRequired: () async => false,
                );
                saved = result != null;
              },
              child: const Text('Visibility'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Visibility'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Public'));
      await tester.pumpAndSettle();
      expect(find.byType(PropertyVisibilitySheet), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expired subscriptions open the same renewal popup once and can be paid',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final checkout = _Checkout();
      final expired = AccountSubscription(
        tier: PlanTier.gold,
        startsAt: DateTime(2026, 1),
        expiresAt: DateTime(2026, 2),
        cancelAtPeriodEnd: false,
      );
      final server = StubServer.always(
        200,
        jsonEncode({
          'quote': 'signed',
          'amount': 8.9,
          'currency': 'USD',
          'periodEnd': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'isUpgrade': false,
        }),
      );
      await pumpTestApp(
        tester,
        const Scaffold(body: ExpiredSubscriptionAlert()),
        overrides: [
          userProfileProvider.overrideWith((ref) async => _user),
          expiredSubscriptionProvider.overrideWith((ref) async => expired),
          accountSubscriptionProvider.overrideWith((ref) async => null),
          paymentRepositoryProvider.overrideWithValue(
            PaymentRepository(server.dio),
          ),
          paymentCheckoutServiceProvider.overrideWithValue(checkout),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Renew your subscription'), findsOneWidget);
      expect(find.byType(UpgradeSubscriptionPage), findsOneWidget);
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
      expect(checkout.calls, ['gold']);
      await tester.ensureVisible(find.text('Back to Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.byType(UpgradeSubscriptionPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
