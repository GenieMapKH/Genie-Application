import 'plan_tier.dart';
import 'subscription_plan.dart';

/// How many listings an account has live against what its plan allows.
class PublishingAllowance {
  final PlanTier tier;

  /// Listings that are live or waiting for their payment.
  final int used;

  const PublishingAllowance({required this.tier, required this.used});

  /// Listing statuses that take up a place in the plan.
  static const countedStatuses = ['Active', 'Pending'];

  int get limit => PlanCatalog.of(tier).listingLimit;

  /// True when one more listing still fits in the plan, so publishing it
  /// costs nothing more.
  bool get hasRoom => used < limit;
}
