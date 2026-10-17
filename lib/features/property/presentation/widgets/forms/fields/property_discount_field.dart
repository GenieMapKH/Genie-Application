import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:genie/l10n/l10n.dart';

/// Optional discount, offered for every property type: a number and whether
/// it is a percentage of the price or USD off it.
class PropertyDiscountField extends StatelessWidget {
  final TextEditingController controller;

  /// 'percent' or 'amount'.
  final String discountType;
  final ValueChanged<String> onTypeChanged;
  final bool hasError;
  final Key? focusKey;

  const PropertyDiscountField({
    super.key,
    required this.controller,
    required this.discountType,
    required this.onTypeChanged,
    this.hasError = false,
    this.focusKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: focusKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertySectionTitle(
          title: context.l10n.propertyDiscount,
          required: false,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: defaultPropertyInputDecoration(
                  context,
                  context.l10n.propertyDiscountHint,
                  hasError: hasError,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'percent', label: Text('%')),
                ButtonSegment(value: 'amount', label: Text('USD')),
              ],
              selected: {discountType},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => onTypeChanged(selection.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: context.colors.primarySoft,
                selectedForegroundColor: context.colors.accent,
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            context.l10n.propertyDiscountInvalid,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.colors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
