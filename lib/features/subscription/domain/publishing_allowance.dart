import 'plan_tier.dart';
import 'subscription_plan.dart';

/// How many listings an account has live against what its plan allows.
class PublishingAllowance {
  final PlanTier tier;

  /// Active listings using the plan, excluding separately paid listings.
  final int used;
  final int? purchasedLimit;

  const PublishingAllowance({
    required this.tier,
    required this.used,
    this.purchasedLimit,
  });

  int get limit => purchasedLimit ?? PlanCatalog.of(tier).listingLimit;

  /// True when one more listing still fits in the plan, so publishing it
  /// costs nothing more.
  bool get hasRoom => used < limit;
}
