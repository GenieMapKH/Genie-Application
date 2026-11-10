import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tilomnov/core/device/app_haptics.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/payment/domain/payment_method.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// "Select Payment Method": the [methods] on offer, one of which may be
/// [selected], with the note that prices include tax.
class PaymentMethodSection extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod>? onSelected;

  const PaymentMethodSection({
    super.key,
    required this.methods,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.paymentSelectMethod,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.info_outline_rounded, size: 14, color: colors.textMuted),
            const SizedBox(width: 4),
            Text(
              l10n.paymentTaxIncluded,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final method in methods)
          PaymentMethodTile(
            method: method,
            selected: method == selected,
            onTap: onSelected == null ? null : () => onSelected!(method),
          ),
      ],
    );
  }
}

/// One way to pay, with its mark, what it does and a radio.
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (title, subtitle) = switch (method) {
      PaymentMethod.abaPay => (l10n.paymentAbaPay, l10n.paymentAbaPayHint),
      PaymentMethod.abaKhqr => (l10n.paymentAbaKhqr, l10n.paymentAbaKhqrHint),
    };

    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? colors.primarySoft : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.highlight : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap == null
                ? null
                : () {
                    AppHaptics.selection();
                    onTap!();
                  },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const _AbaMark(),
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
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
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
        ),
      ),
    );
  }
}

/// ABA's own payment mark, exactly as the bank supplied it (never tinted
/// or redrawn: the bank is strict about its logo).
class _AbaMark extends StatelessWidget {
  const _AbaMark();

  static const asset = 'assets/icons/payment_aba_khqr.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: 44, height: 44);
  }
}
