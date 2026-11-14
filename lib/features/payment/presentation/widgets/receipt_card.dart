import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/features/payment/domain/payment_receipt.dart';
import 'package:tilomnov/features/payment/presentation/payment_feedback.dart';
import 'package:tilomnov/features/payment/presentation/widgets/summary_table.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The receipt as a picture to keep: brand, amount and every detail of the
/// payment. Always drawn light, like paper, whatever the app's theme.
class ReceiptCard extends StatelessWidget {
  final PaymentReceipt receipt;

  const ReceiptCard({super.key, required this.receipt});

  static const width = 360.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const colors = AppColors.light;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final method = switch (receipt.method) {
      PaymentMethod.abaPay => l10n.paymentAbaPay,
      PaymentMethod.abaKhqr => l10n.paymentAbaKhqr,
    };

    return Theme(
      data: Theme.of(
        context,
      ).copyWith(brightness: Brightness.light, extensions: const [colors]),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        color: colors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tilomnov',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1F36),
              ),
            ),
            const SizedBox(height: 18),
            const Icon(
              LucideIcons.circleCheck,
              size: 44,
              color: Color(0xFF1FC79B),
            ),
            const SizedBox(height: 8),
            Text(
              formatUsd(receipt.amountUsd),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SummaryTable(
              title: receipt.isSimulation
                  ? l10n.paymentSimulationNotice
                  : l10n.paymentReceiptTitle,
              rows: [
                (l10n.paymentReceiptTransaction, '#${receipt.transactionId}'),
                (
                  l10n.paymentReceiptDate,
                  DateFormat.yMMMd(locale).add_Hm().format(receipt.paidAt),
                ),
                (l10n.paymentReceiptItem, receipt.item),
                (l10n.paymentReceiptMethod, method),
                if (receipt.email case final email?)
                  (l10n.paymentReceiptEmail, email),
                (
                  l10n.paymentReceiptStatus,
                  receipt.isSimulation
                      ? l10n.paymentSimulation
                      : l10n.paymentReceiptPaid,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.paymentTaxIncluded,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
