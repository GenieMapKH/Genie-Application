import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/publishing_allowance.dart';
import 'package:tilomnov/features/subscription/domain/account_subscription.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';

/// Debug builds only: `--dart-define=PREVIEW_PLAN_TIER=gold` shows the app
/// as a Gold subscriber (profile frame, current plan) without paying.
const _previewTier = kDebugMode
    ? String.fromEnvironment('PREVIEW_PLAN_TIER')
    : '';

/// Refetched for each account; paid benefits expire even while the app stays open.
final accountSubscriptionProvider = FutureProvider<AccountSubscription?>((
  ref,
) async {
  final userId = (await ref.watch(userProfileProvider.future))?.id;
  if (userId == null) return null;
  final subscription = await ref
      .watch(paymentRepositoryProvider)
      .fetchSubscription();
  if (subscription != null) {
    final remaining = subscription.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return null;
    final timer = Timer(remaining, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return subscription;
});

/// The signed-in user's subscription tier; Free for a guest.
final currentPlanTierProvider = Provider<PlanTier>((ref) {
  if (_previewTier.isNotEmpty) return PlanTier.fromApi(_previewTier);
  final subscription = ref.watch(accountSubscriptionProvider).valueOrNull;
  return subscription != null && subscription.expiresAt.isAfter(DateTime.now())
      ? subscription.tier
      : PlanTier.free;
});

/// How many listings the signed-in user has live against their plan. Read
/// again whenever their listings change.
final publishingAllowanceProvider = FutureProvider<PublishingAllowance>((
  ref,
) async {
  final displayedTier = ref.watch(currentPlanTierProvider);
  ref.watch(ownListingsRevisionProvider);
  if (!ref.watch(isSignedInProvider)) {
    return PublishingAllowance(tier: displayedTier, used: 0);
  }
  final subscription = await ref.watch(accountSubscriptionProvider.future);
  final tier = _previewTier.isNotEmpty
      ? PlanTier.fromApi(_previewTier)
      : subscription?.tier ?? PlanTier.free;
  final counts = await ref
      .watch(propertyRepositoryProvider)
      .fetchOwnCountByStatus();
  final used = PublishingAllowance.countedStatuses.fold(
    0,
    (sum, status) => sum + (counts[status] ?? 0),
  );
  return PublishingAllowance(tier: tier, used: used);
});
