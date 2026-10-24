import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/l10n/l10n.dart';

/// "For sale" / "For rent". Neither is lit while the filter takes any
/// listing type.
class ListingScopeTabs extends StatelessWidget {
  final MapPropertyFilter filter;
  final ValueChanged<List<String>> onSelected;

  const ListingScopeTabs({
    super.key,
    required this.filter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _tab(
            context,
            context.l10n.filterForSale,
            filter.isForSale,
            MapPropertyFilter.forSale,
          ),
          _tab(
            context,
            context.l10n.filterForRent,
            filter.isForRent,
            MapPropertyFilter.forRent,
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    bool selected,
    List<String> types,
  ) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(types),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
