import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';
import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// The listing's type ("House", "Land") floating over a card's photo: glass
/// on phones whose interface is glass, else a white pill.
class PropertyTypePill extends StatelessWidget {
  final String propertyType;

  /// Smaller, for the narrow cards of a grid.
  final bool compact;

  const PropertyTypePill({
    super.key,
    required this.propertyType,
    this.compact = false,
  });

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TintedSvg(
            PropertyFormat.typeIconPath(propertyType),
            width: compact ? 12 : 14,
            height: compact ? 12 : 14,
            color: context.colors.textSecondary,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            propertyValueLabel(context.l10n, propertyType),
            style: GoogleFonts.inter(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (GlassScope.of(context)) {
      return GlassSurface(borderRadius: _radius, child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }
}
