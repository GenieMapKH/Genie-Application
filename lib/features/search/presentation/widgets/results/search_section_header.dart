import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// "Places", "Listings", "People & agencies" above each group of results.
class SearchSectionHeader extends StatelessWidget {
  final String title;
  final double gutter;

  const SearchSectionHeader({super.key, required this.title, this.gutter = 16});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}
