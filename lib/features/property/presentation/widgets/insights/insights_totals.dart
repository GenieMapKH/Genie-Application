import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_insights.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Four tiles: everyone who opened, saved, called and chatted, ever.
class InsightsTotals extends StatelessWidget {
  final PropertyInsights insights;

  const InsightsTotals({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = [
      (Icons.visibility_outlined, insights.views, l10n.insightsTotalViews),
      (Icons.favorite_border, insights.saves, l10n.insightsTotalSaves),
      (Icons.phone_outlined, insights.calls, l10n.insightsTotalCalls),
      (Icons.chat_bubble_outline, insights.chats, l10n.insightsTotalChats),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two by two on a phone, one row on a tablet.
        final perRow = constraints.maxWidth >= 600 ? 4 : 2;
        const spacing = 12.0;
        final width = (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (icon, value, label) in tiles)
              SizedBox(
                width: width,
                child: _Tile(icon: icon, value: value, label: label),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _Tile({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.textMuted),
          const SizedBox(height: 8),
          Text(
            PropertyFormat.count(value),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
