import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/features/search/presentation/widgets/highlighted_text.dart';

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
                    PropertyFormat.money(property.finalPrice),
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
                    PropertyFormat.cardSpecLine(property),
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
    final url = property.imageUrls.isEmpty ? null : property.imageUrls.first;
    // Decoded at the size drawn, not the photo's full size: long lists stay
    // light on memory and scroll smoothly.
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    final placeholder = Container(
      color: colors.divider,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        PropertyFormat.typeIconPath(property.propertyType),
        width: 26,
        height: 26,
        colorFilter: ColorFilter.mode(colors.iconSubtle, BlendMode.srcIn),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: cacheSize,
                memCacheHeight: cacheSize,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
