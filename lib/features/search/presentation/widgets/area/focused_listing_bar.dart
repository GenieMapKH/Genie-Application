import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Under the phone sheet's header while the map is flown to one of its
/// listings: what that listing is, and a "View property" button. It stays
/// in sight when the sheet is collapsed to show the map.
class FocusedListingBar extends StatelessWidget {
  /// Fixed so the sheet can collapse to exactly the header and this bar.
  static const double height = 68;

  static const double _gap = 8;

  final PropertyModel property;
  final VoidCallback onView;

  const FocusedListingBar({
    super.key,
    required this.property,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Container(
      height: height - _gap,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, _gap),
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PropertyFormat.cardPrice(l10n, property),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  PropertyFormat.typeAndListing(l10n, property),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.open_in_full_rounded, size: 18),
            label: Text(l10n.searchViewProperty),
          ),
        ],
      ),
    );
  }
}
