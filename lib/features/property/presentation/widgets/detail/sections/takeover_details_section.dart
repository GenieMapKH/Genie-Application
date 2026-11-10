import 'package:flutter/material.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/takeover_terms.dart';
import 'package:tilomnov/features/property/presentation/takeover_labels.dart';
import 'package:tilomnov/features/property/presentation/widgets/takeover_badge.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';

class TakeoverDetailsSection extends StatelessWidget {
  final TakeoverTerms terms;
  const TakeoverDetailsSection({super.key, required this.terms});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unknown = l10n.takeoverUnknown;
    String money(double? value) =>
        value == null ? unknown : PropertyFormat.takeoverMoney(value);
    String option(String? value) =>
        value == null ? unknown : takeoverValueLabel(l10n, value);
    String date(String? value) => TakeoverTerms.validDate(value)
        ? MaterialLocalizations.of(
            context,
          ).formatMediumDate(DateTime.parse(value!))
        : unknown;
    final rows = <(String, String)>[
      (l10n.takeoverCombinedPrice, money(terms.combinedPrice)),
      (l10n.takeoverSellerAmount, money(terms.sellerAmount)),
      (l10n.takeoverBalance, money(terms.remainingBalance)),
      (l10n.takeoverBalanceDate, date(terms.balanceAsOf)),
      (l10n.takeoverPaymentAmount, money(terms.paymentAmount)),
      (l10n.takeoverFrequency, option(terms.paymentFrequency)),
      (
        l10n.takeoverRemainingMonths,
        terms.remainingMonths == null
            ? unknown
            : l10n.takeoverMonthsValue(terms.remainingMonths!),
      ),
      (l10n.takeoverNextPayment, date(terms.nextPaymentDate)),
      (l10n.takeoverProviderType, option(terms.providerType)),
      (l10n.takeoverProviderName, terms.providerName ?? unknown),
      if (terms.projectName?.isNotEmpty ?? false)
        (l10n.takeoverProjectName, terms.projectName!),
      (l10n.takeoverInterestType, option(terms.interestType)),
      if (terms.annualInterestRate != null)
        (
          l10n.takeoverAnnualRate,
          '${terms.annualInterestRate!.toStringAsFixed(2)}%',
        ),
      (l10n.takeoverTransferStatus, option(terms.transferStatus)),
      (l10n.takeoverBuyerTransferFee, money(terms.transferFee)),
      (l10n.takeoverFeePayer, option(terms.transferFeePayer)),
      (l10n.takeoverBuyerArrears, money(terms.arrearsAmount)),
      if ((terms.arrearsAmount ?? 0) > 0)
        (l10n.takeoverArrearsPayer, option(terms.arrearsPayer)),
      (
        l10n.takeoverHasAdditional,
        terms.hasAdditionalPayments == null
            ? unknown
            : terms.hasAdditionalPayments!
            ? l10n.propertyOptionYes
            : l10n.propertyOptionNo,
      ),
      for (final payment in terms.additionalPayments)
        (
          l10n.takeoverAdditionalAmount,
          '${money(payment.amount)} · ${date(payment.dueDate)}',
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TakeoverBadge.color.withValues(alpha: 0.06),
        border: Border.all(color: TakeoverBadge.color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TakeoverBadge(),
          const SizedBox(height: 12),
          Text(l10n.takeoverCombinedHelp),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.$1,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.$2,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (terms.additionalPayments.isNotEmpty)
            Text(l10n.takeoverAdditionalHelp),
          if (terms.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              l10n.takeoverNotes,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(terms.notes!),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.takeoverBuyerNotice,
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
