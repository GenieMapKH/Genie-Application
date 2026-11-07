import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/features/property/presentation/widgets/property_type_pill.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_card_hero_flight.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/owner_display_name.dart';
import 'package:tilomnov/features/property/presentation/widgets/favorite_heart_button.dart';
import 'package:tilomnov/features/property/presentation/widgets/card_map_button.dart';
import 'package:tilomnov/core/theme/app_shapes.dart';

/// Item card for Saved Properties screen matching Screenshot 1.
/// Explicitly omits the "Edit" button since saved properties may belong to other owners.
class SavedPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggled;

  /// Shows the listing on the home map; no map button when null.
  final VoidCallback? onViewOnMap;

  /// The [Hero] tag its detail sheet grows out of. Cards of one listing on
  /// two pages need different tags, or opening the second page flies the
  /// first page's card into it.
  final String? heroTag;

  const SavedPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.isFavorite = true,
    this.onFavoriteToggled,
    this.onViewOnMap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: property.isPublic ? 1 : 0.45,
          child: GestureDetector(
            onTap: property.isPublic ? onTap : null,
            child: Hero(
              tag: heroTag ?? 'saved_property_hero_${property.id}',
              flightShuttleBuilder: propertyCardFlightShuttle,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  // The shadow keeps the quicker rounded-rectangle outline; under
                  // the card's continuous corners the difference cannot be seen.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  foregroundDecoration: ShapeDecoration(
                    shape: AppShapes.continuous(
                      16,
                      side: BorderSide(color: context.colors.divider),
                    ),
                  ),
                  child: ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(16.0),
                    child: ColoredBox(
                      color: context.colors.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Property image gallery container matching PropertyItemCard
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                PropertyImageGallery(
                                  imageUrls: property.cardImageUrls,
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: PropertyTypePill(
                                    propertyType: property.propertyType,
                                    compact: true,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: FavoriteHeartButton(
                                    isFavorite: isFavorite,
                                    onPressed: onFavoriteToggled,
                                    iconSize: 18,
                                    idleColor: context.colors.textMuted,
                                  ),
                                ),
                                if (property.isPublic && onViewOnMap != null)
                                  Positioned(
                                    bottom: 6,
                                    right: 10,
                                    child: CardMapButton(
                                      onPressed: onViewOnMap!,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Details section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PropertyFormat.cardPrice(
                                    context.l10n,
                                    property,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  PropertyFormat.cardSpecLine(
                                    context.l10n,
                                    property,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  property.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: context.colors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.l10n.propertyListingBy(
                                    ownerDisplayName(
                                      context.l10n,
                                      property.ownerName,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: context.colors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!property.isPublic)
          Positioned(
            top: 48,
            left: 10,
            right: 10,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.l10n.propertyUnavailable,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
