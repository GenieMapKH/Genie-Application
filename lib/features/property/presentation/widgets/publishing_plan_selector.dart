import 'package:flutter/material.dart';

import 'package:tilomnov/core/device/app_haptics.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// How a listing that does not fit in the user's plan gets published.
enum PublishingPlan {
  /// Pay once for this listing.
  oneTime,

  /// Subscribe to a plan with room for more listings.
  subscription,
}

/// "Choose Publishing Plan": shown on a new listing once the user's plan
/// is full, so publishing it costs something.
class PublishingPlanSelector extends StatelessWidget {
  final PublishingPlan? selected;
  final ValueChanged<PublishingPlan> onChanged;

  /// What a one-time publish costs, in US dollars.
  final double oneTimeFee;

  /// Marks the section when Publish was pressed with no plan chosen.
  final bool hasError;

  const PublishingPlanSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.oneTimeFee,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasError ? colors.danger : colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            _PlanOption(
              icon: Icons.receipt_long_rounded,
              title: l10n.publishPlanOneTime,
              subtitle: l10n.publishPlanOneTimeHint(formatUsd(oneTimeFee)),
              selected: selected == PublishingPlan.oneTime,
              onTap: () => onChanged(PublishingPlan.oneTime),
            ),
            Divider(height: 1, indent: 60, color: colors.divider),
            _PlanOption(
              icon: Icons.workspace_premium_rounded,
              title: l10n.publishPlanSubscription,
              subtitle: l10n.publishPlanSubscriptionHint,
              selected: selected == PublishingPlan.subscription,
              onTap: () => onChanged(PublishingPlan.subscription),
              highlighted: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Paints the icon in the brand gold: the option worth a look.
  final bool highlighted;

  const _PlanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: selected ? colors.primarySoft : Colors.transparent,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: highlighted
                      ? colors.highlight.withValues(alpha: 0.18)
                      : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: highlighted ? colors.highlight : colors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? colors.highlight : colors.iconSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
