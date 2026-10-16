import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/search/data/models/place_suggestion.dart';
import 'package:genie/features/search/presentation/widgets/highlighted_text.dart';

/// A suggested place: pin, name, and where it is.
class PlaceResultTile extends StatelessWidget {
  final PlaceSuggestion place;
  final String query;
  final VoidCallback onTap;
  final double gutter;

  const PlaceResultTile({
    super.key,
    required this.place,
    required this.query,
    required this.onTap,
    this.gutter = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secondary = place.secondaryText;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place_rounded, size: 22, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HighlightedText(
                    text: place.primaryText,
                    query: query,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    matchStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (secondary != null && secondary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.north_west_rounded, size: 18, color: colors.iconSubtle),
          ],
        ),
      ),
    );
  }
}
