import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_keyword.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// Every listing feature as a chip; the lit ones must all be on a listing.
class KeywordFilterChips extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const KeywordFilterChips({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final keyword in PropertyKeyword.all)
          _chip(context, keyword, selected.contains(keyword.code)),
      ],
    );
  }

  Widget _chip(BuildContext context, PropertyKeyword keyword, bool isOn) {
    final colors = context.colors;
    final tint = isOn ? colors.primary : colors.textSecondary;
    return GestureDetector(
      onTap: () => onToggle(keyword.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? colors.primarySoft : colors.surfaceMuted,
          border: Border.all(color: isOn ? colors.primary : colors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TintedSvg(keyword.iconPath, width: 14, height: 14, color: tint),
            const SizedBox(width: 6),
            Text(
              propertyKeywordLabel(context.l10n, keyword.code),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
