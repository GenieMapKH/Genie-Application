import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/closest_listings/data/closest_listing.dart';
import 'package:tilomnov/features/property/presentation/widgets/saved_property_card.dart';
import 'package:tilomnov/features/property/utils/nearby_distance_format.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// One listing in the map's pull-up list: how far it is, then its card,
/// which takes the rest of the tile's height.
class ClosestListingTile extends StatelessWidget {
  final ClosestListing listing;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onFavoriteToggled;

  const ClosestListingTile({
    super.key,
    required this.listing,
    required this.isFavorite,
    required this.onOpen,
    required this.onFavoriteToggled,
  });

  /// Font size of the distance line above the card.
  static const double _distanceFontSize = 12.5;

  /// Space the distance line and its gap take above the card, at the
  /// user's text size (a little more than the line needs).
  static double distanceLineHeight(TextScaler scaler) =>
      scaler.scale(_distanceFontSize) * 1.5 + 8;

  /// The Hero tag of a listing's card here, apart from the map's and the
  /// feed's, so opening one never flies another page's card.
  static String heroTagOf(String propertyId) => 'closest_hero_$propertyId';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final distance = formatNearbyDistance(context, listing.distanceMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.near_me_rounded, size: 14, color: colors.accent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.l10n.closestAway(distance),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: _distanceFontSize,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SavedPropertyCard(
            property: listing.property,
            isFavorite: isFavorite,
            heroTag: heroTagOf(listing.property.id),
            onTap: onOpen,
            onFavoriteToggled: onFavoriteToggled,
          ),
        ),
      ],
    );
  }
}
