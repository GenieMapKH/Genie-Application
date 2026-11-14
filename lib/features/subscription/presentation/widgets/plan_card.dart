import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/plan_tier_style.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';

/// One subscription plan: its name, monthly price and what it allows.
///
/// The user's [isCurrent] plan is set in the tier's deep metal with how many
/// listings are [used]. [onUpgrade] adds a checkout button for another plan.
class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;

  /// Listings live now, shown on the current plan; null while unknown.
  final int? used;
  final VoidCallback? onUpgrade;
  final Widget? status;
  final bool annual;
  final int? purchasedLimit;

  const PlanCard({
    super.key,
    required this.plan,
    this.isCurrent = false,
    this.used,
    this.onUpgrade,
    this.status,
    this.annual = false,
    this.purchasedLimit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = PlanTierStyle.of(plan.tier);
    final ink = isCurrent ? Colors.white : colors.textPrimary;
    final used = this.used;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCurrent ? style.deepGradient : null,
        color: isCurrent ? null : colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: isCurrent ? null : Border.all(color: colors.border),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: style.deep.last.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _TierEmblem(tier: plan.tier, onDark: isCurrent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.planAccount(plan.tier.label(context.l10n)),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          if (isCurrent && used != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _UsagePill(
                used: used,
                limit: purchasedLimit ?? plan.listingLimit,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _Price(plan: plan, ink: ink, annual: annual),
          if (isCurrent) ...[const SizedBox(height: 14), _CurrentPlanLabel()],
          if (!isCurrent && onUpgrade != null) ...[
            const SizedBox(height: 14),
            _UpgradeButton(tier: plan.tier, onPressed: onUpgrade!),
          ],
          const SizedBox(height: 14),
          _Features(plan: plan, ink: ink),
          if (isCurrent && status != null) ...[
            const SizedBox(height: 14),
            status!,
          ],
        ],
      ),
    );
  }
}

/// The tier's icon in a soft tint of its accent, the way the app marks
/// options elsewhere. On the current plan's dark card it is white.
class _TierEmblem extends StatelessWidget {
  final PlanTier tier;
  final bool onDark;

  const _TierEmblem({required this.tier, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final tint = onDark ? Colors.white : tier.accentOn(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: onDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(PlanTierStyle.of(tier).icon, size: 18, color: tint),
    );
  }
}

class _Price extends StatelessWidget {
  final SubscriptionPlan plan;
  final Color ink;

  final bool annual;

  const _Price({required this.plan, required this.ink, required this.annual});

  @override
  Widget build(BuildContext context) {
    final price = plan.monthlyPriceUsd == 0
        ? r'$0'
        : formatUsd(annual ? plan.annualPriceUsd : plan.monthlyPriceUsd);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: price,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text:
                '  ${annual ? context.l10n.planPerYear : context.l10n.planPerMonth}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ink.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
      style: TextStyle(color: ink, letterSpacing: -0.3),
    );
  }
}

/// "1 / 1 listings used", glassy on the deep metal.
class _UsagePill extends StatelessWidget {
  final int used;
  final int limit;

  const _UsagePill({required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        context.l10n.planListingsUsed(used, limit),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CurrentPlanLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.l10n.planCurrent,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F1F36),
        ),
      ),
    );
  }
}

/// A checkout button, filled with the tier's accent.
class _UpgradeButton extends StatelessWidget {
  final PlanTier tier;
  final VoidCallback onPressed;

  const _UpgradeButton({required this.tier, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final fill = tier.accentOn(context);
    return TactileButton(
      onPressed: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          context.l10n.planUpgradeTo(tier.label(context.l10n)),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: readableOn(fill),
          ),
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  final SubscriptionPlan plan;
  final Color ink;

  const _Features({required this.plan, required this.ink});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lines = [
      l10n.planFeatureLimit(plan.listingLimit),
      switch (plan.tier) {
        PlanTier.free => l10n.planFeatureFree,
        PlanTier.silver => l10n.planFeatureSilver,
        PlanTier.gold => l10n.planFeatureGold,
        PlanTier.diamond => l10n.planFeatureDiamond,
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planFeatures,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: 6),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.circleCheck,
                  size: 16,
                  color: ink.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ink.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
