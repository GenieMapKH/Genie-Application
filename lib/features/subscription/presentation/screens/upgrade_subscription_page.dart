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
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/subscription/domain/subscription_plan.dart';
import 'package:tilomnov/features/subscription/domain/subscription_quote.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/features/subscription/presentation/plan_tier_style.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/subscription/presentation/widgets/plan_card.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// Checkout for one subscription [plan]: what it costs, how to pay, and
/// "Subscribe", lit once a payment method is picked. Once paid it shows the
/// success screen, which [onFinished] closes along with this checkout (by
/// default popping both, with true).
class UpgradeSubscriptionPage extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;
  final VoidCallback? onFinished;
  final bool isRenewal;

  const UpgradeSubscriptionPage({
    super.key,
    required this.plan,
    this.onFinished,
    this.isRenewal = false,
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
  bool _annual = false;

  Future<void> _subscribe(PaymentMethod method, SubscriptionQuote quote) async {
    if (_paying ||
        ref.read(currentPlanTierProvider).index >= widget.plan.tier.index) {
      return;
    }
    setState(() => _paying = true);
    try {
      final checkout = ref.read(paymentCheckoutServiceProvider);
      final plan = widget.plan;
      final outcome = await checkout.payForSubscription(
        plan.tier.name,
        method,
        quote: quote.token,
      );
      if (!mounted) return;
      if (!outcome.isPaid) {
        showUnfinishedPayment(
          context,
          outcome.result,
          transactionId: outcome.transactionId,
        );
        return;
      }
      ref.invalidate(accountSubscriptionProvider);
      ref.invalidate(expiredSubscriptionProvider);
      ownListingsChangedFrom(ref);
      ref.invalidate(publishingAllowanceProvider);
      await showPaymentSuccess(
        context,
        receipt: PaymentReceipt(
          transactionId: outcome.transactionId ?? '',
          amountUsd: outcome.amountUsd ?? quote.amount,
          item: context.l10n.paymentItemSubscription(
            plan.tier.label(context.l10n),
          ),
          method: method,
          paidAt: outcome.paidAt ?? DateTime.now(),
          email: ref.read(userProfileProvider).valueOrNull?.email,
        ),
        onDone: widget.onFinished ?? _closeCheckout,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Subscription checkout failed', e, stackTrace);
      ref.invalidate(subscriptionQuoteProvider(widget.plan.tier));
      ref.invalidate(annualSubscriptionQuoteProvider(widget.plan.tier));
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
    final current = ref.watch(currentPlanTierProvider);
    final isCurrent = current == plan.tier;
    final eligible = current.index < plan.tier.index;
    final active = ref.watch(accountSubscriptionProvider).valueOrNull;
    final annual = active == null ? _annual : active.billingPeriod == 'annual';
    final quoteProvider = annual
        ? annualSubscriptionQuoteProvider(plan.tier)
        : subscriptionQuoteProvider(plan.tier);
    final quoteState = eligible ? ref.watch(quoteProvider) : null;
    final quote = quoteState?.valueOrNull;
    final price = quote == null ? '...' : formatUsd(quote.amount);

    return AppPageScaffold(
      title: widget.isRenewal
          ? l10n.publishingRenewSubscriptionTitle
          : l10n.planUpgradeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                  widget.isRenewal
                      ? l10n.publishingRenewSubscriptionMessage
                      : l10n.planUpgradeIntro,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                if (quoteState?.isLoading == true)
                  const LinearProgressIndicator(),
                if (quoteState?.hasError == true) ...[
                  Text(
                    failureMessage(
                      l10n,
                      error: quoteState?.error,
                      fallback: l10n.paymentCouldNotStart,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(quoteProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.planStatusRetry),
                  ),
                ],
                if (active == null && eligible)
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.paymentMonthly),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.planAnnualOffer),
                      ),
                    ],
                    selected: {annual},
                    onSelectionChanged: _paying
                        ? null
                        : (value) => setState(() => _annual = value.single),
                  ),
                const SizedBox(height: 12),
                PlanCard(plan: plan, isCurrent: isCurrent, annual: annual),
                const SizedBox(height: 28),
                SummaryTable(
                  title: l10n.paymentBillingSummary,
                  emphasizeLast: true,
                  rows: [
                    (l10n.paymentPlan, plan.tier.label(l10n)),
                    (l10n.paymentPrice, price),
                    (
                      l10n.paymentBillingCycle,
                      quote?.isUpgrade == true
                          ? DateFormat.yMMMd(
                              l10n.localeName,
                            ).format(quote!.periodEnd.toLocal())
                          : annual
                          ? l10n.paymentAnnual
                          : l10n.paymentMonthly,
                    ),
                    if (quote != null)
                      (
                        l10n.planExpiryDate,
                        DateFormat.yMMMd(
                          l10n.localeName,
                        ).add_jm().format(quote.periodEnd.toLocal()),
                      ),
                    (l10n.paymentTotal, price),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.planManualRenewal,
                  style: TextStyle(color: context.colors.textMuted),
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
            label: isCurrent ? l10n.planCurrent : l10n.planSubscribe,
            isBusy: _paying,
            onPressed: method == null || !eligible || quote == null
                ? null
                : () => _subscribe(method, quote),
          ),
        ],
      ),
    );
  }
}
