import 'plan_tier.dart';

/// The account's paid period, owned by the payment service.
class AccountSubscription {
  final PlanTier tier;
  final String billingPeriod;
  final DateTime startsAt;
  final DateTime expiresAt;
  final bool cancelAtPeriodEnd;

  const AccountSubscription({
    required this.tier,
    this.billingPeriod = 'monthly',
    required this.startsAt,
    required this.expiresAt,
    required this.cancelAtPeriodEnd,
  });

  factory AccountSubscription.fromJson(Map<String, dynamic> json) =>
      AccountSubscription(
        tier: PlanTier.fromApi(json['tier'] as String?),
        billingPeriod: json['billingPeriod'] as String? ?? 'monthly',
        startsAt: DateTime.parse(json['currentPeriodStart'] as String),
        expiresAt: DateTime.parse(json['currentPeriodEnd'] as String),
        cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      );
}
