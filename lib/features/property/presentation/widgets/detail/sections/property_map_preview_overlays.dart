import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/features/home/utils/map/map_measurements.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// The plot's area in a corner of the preview, for a plot too small or too
/// thin on screen to hold it.
class PropertyMapAreaChip extends StatelessWidget {
  final double area;

  const PropertyMapAreaChip({super.key, required this.area});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        formatArea(area),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// Round button out of the preview to the full map.
class PropertyMapViewButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PropertyMapViewButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        onPressed: onPressed,
        tooltip: context.l10n.propertyViewOnMap,
        icon: Icon(
          Icons.open_in_full_rounded,
          size: 18,
          color: context.colors.textSecondary,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
