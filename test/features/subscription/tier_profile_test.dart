import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/screens/user_profile_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/settings/presentation/screens/privacy_cookies_page.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/presentation/screens/subscription_plans_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/tier_avatar_frame.dart';

import '../../support/test_app.dart';

final _profile = UserProfile(
  id: 'u1',
  username: 'sokha',
  name: 'Sokha Chan',
  role: 'user',
  createdAt: DateTime(2026),
);

Future<void> _openAccount(WidgetTester tester, PlanTier tier) async {
  // Tall enough to show the whole account menu.
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await pumpTestApp(
    tester,
    const UserProfilePage(),
    overrides: [
      userProfileProvider.overrideWith((ref) async => _profile),
      currentPlanTierProvider.overrideWithValue(tier),
      accountSubscriptionProvider.overrideWith((ref) async => null),
    ],
  );
}

/// The frame's light runs round for ever, so settle by time instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a Gold subscriber gets the gold frame and badge', (
    tester,
  ) async {
    await _openAccount(tester, PlanTier.gold);
    await _settle(tester);

    expect(find.text('GOLD MEMBER'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    final frame = tester.widget<TierAvatarFrame>(find.byType(TierAvatarFrame));
    expect(frame.tier, PlanTier.gold);
    expect(find.text('Gold'), findsOneWidget); // the Subscription Plan row
  });

  testWidgets('a free account has a bare picture and no badge', (tester) async {
    await _openAccount(tester, PlanTier.free);
    await tester.pumpAndSettle();

    expect(find.textContaining('MEMBER'), findsNothing);
    expect(find.text('Free'), findsOneWidget);
  });

  testWidgets('the Privacy & cookies row opens the policy', (tester) async {
    await _openAccount(tester, PlanTier.free);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Privacy & cookies'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyCookiesPage), findsOneWidget);
    expect(find.text('What we collect'), findsOneWidget);
  });

  testWidgets('the Subscription Plan row opens the plans', (tester) async {
    await _openAccount(tester, PlanTier.free);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscription Plan'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionPlansPage), findsOneWidget);
  });
}
