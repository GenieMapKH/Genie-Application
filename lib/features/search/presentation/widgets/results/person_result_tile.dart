import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/presentation/widgets/results/highlighted_text.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/media/user_avatar.dart';

/// Someone who posts listings: picture, name, handle and how many they have.
class PersonResultTile extends StatelessWidget {
  final PublisherSummary person;
  final String query;
  final VoidCallback onTap;
  final double gutter;

  const PersonResultTile({
    super.key,
    required this.person,
    required this.query,
    required this.onTap,
    this.gutter = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = context.l10n.searchListingCount(person.listingCount);
    final handle = person.username;
    final subtitle = handle == null || handle == person.displayName
        ? count
        : '@$handle · $count';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 10),
        child: Row(
          children: [
            UserAvatar(
              name: person.displayName,
              avatarUrl: person.avatarUrl,
              radius: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HighlightedText(
                    text: person.displayName,
                    query: query,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    matchStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: colors.iconSubtle),
          ],
        ),
      ),
    );
  }
}
