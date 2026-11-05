import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/features/property/presentation/widgets/property_type_pill.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/owner_display_name.dart';
import 'package:tilomnov/features/property/presentation/widgets/favorite_heart_button.dart';

/// The card that rises above the bottom nav when a property is selected on the
/// map. Tapping it — or swiping it up — opens the full detail sheet.
class PropertyItemCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggled;

  const PropertyItemCard({
    super.key,
    required this.property,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'property_card_hero_${property.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            // The shadow keeps the quicker rounded-rectangle outline; under
            // the card's continuous corners the difference cannot be seen.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(16.0),
              child: ColoredBox(
                color: context.colors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PropertyImageGallery(
                            imageUrls: property.cardImageUrls,
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: PropertyTypePill(
                              propertyType: property.propertyType,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: FavoriteHeartButton(
                              isFavorite: isFavorite,
                              onPressed: onFavoriteToggled,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: _Details(property: property),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final PropertyModel property;

  const _Details({required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PropertyFormat.cardPrice(context.l10n, property),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          PropertyFormat.cardSpecLine(context.l10n, property),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          property.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.propertyListingBy(
            ownerDisplayName(context.l10n, property.ownerName),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.colors.textHint,
          ),
        ),
      ],
    );
  }
}
