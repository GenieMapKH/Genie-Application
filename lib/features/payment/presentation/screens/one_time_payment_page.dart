import 'package:flutter/material.dart';
import 'package:tilomnov/features/payment/application/payment_config.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/payment/presentation/widgets/checkout_button_bar.dart';
import 'package:tilomnov/features/payment/presentation/widgets/payment_method_section.dart';
import 'package:tilomnov/features/payment/presentation/widgets/summary_table.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// Checkout for publishing one listing without a subscription: the listing
/// ([listingRows]), the [fee], how to pay, and "Publish Property", lit once
/// a method is picked. [onPublish] does the publishing and paying, and says
/// whether it is done; the page then pops with true.
class OneTimePaymentPage extends StatefulWidget {
  final List<(String, String)> listingRows;
  final double fee;
  final Future<bool> Function(PaymentMethod method) onPublish;

  const OneTimePaymentPage({
    super.key,
    required this.listingRows,
    required this.fee,
    required this.onPublish,
  });

  /// A one-time publish is paid by KHQR, with any banking app.
  static const methods = [PaymentMethod.abaKhqr];

  @override
  State<OneTimePaymentPage> createState() => _OneTimePaymentPageState();
}

class _OneTimePaymentPageState extends State<OneTimePaymentPage> {
  PaymentMethod? _method;
  bool _publishing = false;

  Future<void> _publish(PaymentMethod method) async {
    setState(() => _publishing = true);
    try {
      final done = await widget.onPublish(method);
      if (done && mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final method = _method;
    final fee = formatUsd(widget.fee);

    return AppPageScaffold(
      title: l10n.paymentOneTimeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                  l10n.paymentOneTimeIntro,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                if (!PaymentConfig.enabled) Text(l10n.paymentSimulationNotice),
                SummaryTable(
                  title: l10n.paymentPropertyInformation,
                  rows: widget.listingRows,
                ),
                const SizedBox(height: 28),
                SummaryTable(
                  title: l10n.paymentBillingSummary,
                  emphasizeLast: true,
                  rows: [
                    (l10n.paymentPrice, fee),
                    (l10n.paymentBillingCycle, l10n.paymentOneTime),
                    (l10n.paymentTotal, fee),
                  ],
                ),
                const SizedBox(height: 28),
                PaymentMethodSection(
                  methods: OneTimePaymentPage.methods,
                  selected: method,
                  onSelected: _publishing
                      ? null
                      : (picked) => setState(() => _method = picked),
                ),
              ],
            ),
          ),
          CheckoutButtonBar(
            label: l10n.paymentPublishProperty,
            isBusy: _publishing,
            onPressed: method == null ? null : () => _publish(method),
          ),
        ],
      ),
    );
  }
}
