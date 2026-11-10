import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// The top of a card in the Locate Property sheet: a small icon badge, then
/// the card's title and a line saying what it does.
class UtmSectionTitle extends StatelessWidget {
  /// Drawn 20 px, tinted the accent colour.
  final Widget Function(Color color) icon;
  final String title;
  final String subtitle;

  const UtmSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const double _badge = 36;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: _badge,
          height: _badge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: icon(colors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
