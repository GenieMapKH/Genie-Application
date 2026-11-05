import 'package:flutter/material.dart';

import 'package:tilomnov/features/subscription/domain/plan_tier.dart';
import 'package:tilomnov/features/subscription/presentation/plan_tier_style.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// "GOLD MEMBER" in the tier's metal, under a subscriber's name.
class PlanTierChip extends StatelessWidget {
  final PlanTier tier;

  const PlanTierChip({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final style = PlanTierStyle.of(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: style.metalGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.onMetal),
          const SizedBox(width: 4),
          Text(
            context.l10n.planMember(tier.label(context.l10n)).toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: style.onMetal,
            ),
          ),
        ],
      ),
    );
  }
}
