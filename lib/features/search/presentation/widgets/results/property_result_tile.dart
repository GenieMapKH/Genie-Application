import 'package:tilomnov/shared/widgets/media/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/features/search/presentation/widgets/results/highlighted_text.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// A listing in a results list: photo, title, price and its main figures.
/// Used by the search page and by the results panel on the map.
class PropertyResultTile extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  /// Words to highlight in the title; empty highlights nothing.
  final String query;
  final double gutter;

  const PropertyResultTile({
    super.key,
    required this.property,
    required this.onTap,
    this.query = '',
    this.gutter = 16,
  });

  static const double _thumbnailSize = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 8),
        child: Row(
          children: [
            _Thumbnail(property: property, size: _thumbnailSize),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    PropertyFormat.cardPrice(context.l10n, property),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  HighlightedText(
                    text: property.title,
                    query: query,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                    matchStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PropertyFormat.cardSpecLine(context.l10n, property),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final PropertyModel property;
  final double size;

  const _Thumbnail({required this.property, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = property.cardImageUrls.isEmpty
        ? null
        : property.cardImageUrls.first;

    final placeholder = Container(
      color: colors.divider,
      alignment: Alignment.center,
      child: TintedSvg(
        PropertyFormat.typeIconPath(property.propertyType),
        width: 26,
        height: 26,
        color: colors.iconSubtle,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : AppNetworkImage(
                url: url,
                placeholder: placeholder,
                errorWidget: placeholder,
              ),
      ),
    );
  }
}
