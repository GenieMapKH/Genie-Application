import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/payment/presentation/payment_providers.dart';
import 'package:tilomnov/features/payment/presentation/payment_success.dart';
import 'package:tilomnov/features/payment/presentation/widgets/checkout_button_bar.dart';
import 'package:tilomnov/features/payment/presentation/widgets/payment_method_section.dart';
import 'package:tilomnov/features/payment/presentation/widgets/summary_table.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/presentation/plan_tier_style.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/plan_card.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// Checkout for one subscription [plan]: what it costs, how to pay, and
/// "Subscribe", lit once a payment method is picked. Once paid it shows the
/// success screen, which [onFinished] closes along with this checkout (by
/// default popping both, with true).
class UpgradeSubscriptionPage extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;
  final VoidCallback? onFinished;

  const UpgradeSubscriptionPage({
    super.key,
    required this.plan,
    this.onFinished,
  });

  /// Subscriptions are paid in ABA Mobile.
  static const methods = [PaymentMethod.abaPay];

  @override
  ConsumerState<UpgradeSubscriptionPage> createState() =>
      _UpgradeSubscriptionPageState();
}

class _UpgradeSubscriptionPageState
    extends ConsumerState<UpgradeSubscriptionPage> {
  PaymentMethod? _method;
  bool _paying = false;

  Future<void> _subscribe(PaymentMethod method) async {
    setState(() => _paying = true);
    try {
      final checkout = ref.read(paymentCheckoutServiceProvider);
      final plan = widget.plan;
      final outcome = await checkout.payForSubscription(plan.tier.name, method);
      if (!mounted) return;
      if (!outcome.isPaid) {
        showUnfinishedPayment(context, outcome.result);
        return;
      }
      ref.invalidate(accountSubscriptionProvider);
      ref.invalidate(publishingAllowanceProvider);
      await showPaymentSuccess(
        context,
        ref,
        receipt: PaymentReceipt(
          transactionId: outcome.transactionId ?? '',
          amountUsd: plan.monthlyPriceUsd,
          item: context.l10n.paymentItemSubscription(
            plan.tier.label(context.l10n),
          ),
          method: method,
          paidAt: DateTime.now(),
          email: ref.read(userProfileProvider).valueOrNull?.email,
        ),
        onDone: widget.onFinished ?? _closeCheckout,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Subscription checkout failed', e, stackTrace);
      if (mounted) showPaymentError(context, e);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  /// Closes the success screen and this checkout, saying it was paid.
  void _closeCheckout() {
    final checkout = ModalRoute.of(context);
    Navigator.of(context)
      ..popUntil((route) => route == checkout)
      ..pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plan = widget.plan;
    final method = _method;
    final price = formatUsd(plan.monthlyPriceUsd);

    return AppPageScaffold(
      title: l10n.planUpgradeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                  l10n.planUpgradeIntro,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                if (ref.watch(paymentCheckoutServiceProvider).isSimulation)
                  Text(l10n.paymentSimulationNotice),
                PlanCard(plan: plan),
                const SizedBox(height: 28),
                SummaryTable(
                  title: l10n.paymentBillingSummary,
                  emphasizeLast: true,
                  rows: [
                    (l10n.paymentPlan, plan.tier.label(l10n)),
                    (l10n.paymentPrice, price),
                    (l10n.paymentBillingCycle, l10n.paymentMonthly),
                    (l10n.paymentTotal, price),
                  ],
                ),
                const SizedBox(height: 28),
                PaymentMethodSection(
                  methods: UpgradeSubscriptionPage.methods,
                  selected: method,
                  onSelected: _paying
                      ? null
                      : (picked) => setState(() => _method = picked),
                ),
              ],
            ),
          ),
          CheckoutButtonBar(
            label: l10n.planSubscribe,
            isBusy: _paying,
            onPressed: method == null ? null : () => _subscribe(method),
          ),
        ],
      ),
    );
  }
}
