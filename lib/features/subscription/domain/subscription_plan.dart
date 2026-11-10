import 'plan_tier.dart';

/// What one subscription tier costs and allows.
class SubscriptionPlan {
  final PlanTier tier;

  /// US dollars a month, tax included.
  final double monthlyPriceUsd;

  /// How many listings may be published at the same time.
  final int listingLimit;

  double get annualPriceUsd => monthlyPriceUsd * 10;

  const SubscriptionPlan({
    required this.tier,
    required this.monthlyPriceUsd,
    required this.listingLimit,
  });
}

/// Every plan offered, cheapest first, and the one-time publishing fee.
///
/// Display values only. The payment service owns prices and publishing limits
/// in its plan-catalog.ts and checks them independently of the app.
abstract final class PlanCatalog {
  static const plans = [
    SubscriptionPlan(tier: PlanTier.free, monthlyPriceUsd: 0, listingLimit: 1),
    SubscriptionPlan(
      tier: PlanTier.silver,
      monthlyPriceUsd: 7,
      listingLimit: 10,
    ),
    SubscriptionPlan(
      tier: PlanTier.gold,
      monthlyPriceUsd: 15,
      listingLimit: 30,
    ),
    SubscriptionPlan(
      tier: PlanTier.diamond,
      monthlyPriceUsd: 29,
      listingLimit: 100,
    ),
  ];

  /// What publishing one more listing costs without a subscription.
  static const oneTimePublishFeeUsd = 2.00;

  /// Share of every price that is tax (prices are shown tax included).
  static const taxRate = 0.10;

  static SubscriptionPlan of(PlanTier tier) =>
      plans.firstWhere((plan) => plan.tier == tier);
}
