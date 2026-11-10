import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/screens/upgrade_subscription_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/plan_card.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/subscription_status.dart';

/// Every subscription plan; only higher tiers can replace an active plan.
class SubscriptionPlansPage extends ConsumerWidget {
  const SubscriptionPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentPlanTierProvider);
    final subscriptionState = ref.watch(accountSubscriptionProvider);
    final canPurchase =
        !subscriptionState.isLoading && !subscriptionState.hasError;
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
          if (subscriptionState.hasError && !current.isPaid)
            const SubscriptionStatus(),
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
              purchasedLimit: ref
                  .watch(publishingAllowanceProvider)
                  .valueOrNull
                  ?.limit,
              status: plan.tier == current && plan.tier.isPaid
                  ? const SubscriptionStatus(onDark: true)
                  : null,
              onUpgrade:
                  canPurchase &&
                      plan.tier.isPaid &&
                      plan.tier.index > current.index
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
