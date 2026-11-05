import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/screens/upgrade_subscription_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/plan_card.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// Every subscription plan, the user's own first. Picking a higher one opens
/// its checkout. Pops with true once the user has subscribed.
class SubscriptionPlansPage extends ConsumerWidget {
  const SubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentPlanTierProvider);
    final used = ref.watch(publishingAllowanceProvider).valueOrNull?.used;

    // After a payment, "Back to Home" closes the success screen, the
    // checkout and these plans together, back to where they were opened.
    void finish() {
      final plans = ModalRoute.of(context);
      Navigator.of(context)
        ..popUntil((route) => route == plans)
        ..pop(true);
    }

    Future<void> upgrade(SubscriptionPlan plan) => context.pushPage<void>(
      UpgradeSubscriptionPage(plan: plan, onFinished: finish),
    );

    return AppPageScaffold(
      title: context.l10n.accountSubscription,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            context.l10n.planChooseIntro,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          for (final plan in PlanCatalog.plans) ...[
            PlanCard(
              plan: plan,
              isCurrent: plan.tier == current,
              used: used,
              // Only a higher plan is offered; changing down is not built.
              onUpgrade: plan.tier.index > current.index
                  ? () => upgrade(plan)
                  : null,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
