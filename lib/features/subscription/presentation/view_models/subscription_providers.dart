import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/publishing_allowance.dart';

/// Debug builds only: `--dart-define=PREVIEW_PLAN_TIER=gold` shows the app
/// as a Gold subscriber (profile frame, current plan) without paying.
const _previewTier = kDebugMode
    ? String.fromEnvironment('PREVIEW_PLAN_TIER')
    : '';

/// The tier bought with a simulated payment (payments switched off): the
/// server never hears of it, so it lasts until the app closes or the user
/// signs out.
final simulatedPlanTierProvider = StateProvider<PlanTier?>((ref) {
  ref.watch(isSignedInProvider);
  return null;
});

/// The signed-in user's subscription tier; Free for a guest.
final currentPlanTierProvider = Provider<PlanTier>((ref) {
  if (_previewTier.isNotEmpty) return PlanTier.fromApi(_previewTier);
  final simulated = ref.watch(simulatedPlanTierProvider);
  if (simulated != null) return simulated;
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return PlanTier.fromApi(profile?.subscriptionTier);
});

/// How many listings the signed-in user has live against their plan. Read
/// again whenever their listings change.
final publishingAllowanceProvider = FutureProvider<PublishingAllowance>((
  ref,
) async {
  final tier = ref.watch(currentPlanTierProvider);
  ref.watch(ownListingsRevisionProvider);
  if (!ref.watch(isSignedInProvider)) {
    return PublishingAllowance(tier: tier, used: 0);
  }
  final counts = await ref
      .watch(propertyRepositoryProvider)
      .fetchOwnCountByStatus();
  final used = PublishingAllowance.countedStatuses.fold(
    0,
    (sum, status) => sum + (counts[status] ?? 0),
  );
  return PublishingAllowance(tier: tier, used: used);
});
