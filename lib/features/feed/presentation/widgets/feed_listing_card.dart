import 'package:flutter/material.dart';
import 'package:tilomnov/features/property/presentation/widgets/takeover_badge.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_post_header.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:tilomnov/features/property/presentation/widgets/share/property_share_sheet.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// A publisher's post, with its own feed layout rather than a saved card.
class FeedListingCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavorite;
  final VoidCallback onOpen;
  final ValueChanged<Rect> onOpenOwner;
  final VoidCallback onFavoriteToggled;
  final VoidCallback? onViewOnMap;

  const FeedListingCard({
    super.key,
    required this.property,
    required this.isFavorite,
    required this.onOpen,
    required this.onOpenOwner,
    required this.onFavoriteToggled,
    this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final previousPrice = property.recentPreviousPrice();
    final open = property.isPublic ? onOpen : null;

    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeedPostHeader(property: property, onOpenOwner: onOpenOwner),
          InkWell(
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Text(
                property.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          Semantics(
            label: property.title,
            button: open != null,
            child: GestureDetector(
              onTap: open,
              child: Hero(
                tag: 'feed_property_hero_${property.id}',
                child: AspectRatio(
                  aspectRatio: 6 / 5,
                  child: PropertyImageGallery(
                    key: ValueKey(property.id),
                    imageUrls: property.cardImageUrls,
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (previousPrice != null) ...[
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_down_rounded,
                          size: 16,
                          color: colors.success,
                        ),
                        Text(
                          l10n.feedPriceDropped,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          PropertyFormat.money(previousPrice),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (property.isTakeover) ...[
                    const TakeoverBadge(),
                    const SizedBox(height: 8),
                    Text(PropertyFormat.takeoverSummary(l10n, property)),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    PropertyFormat.cardPrice(l10n, property),
                    style: GoogleFonts.inter(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    PropertyFormat.cardSpecLine(l10n, property),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.6,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (!property.isPublic) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.propertyUnavailable,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, color: colors.divider),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Semantics(
                  toggled: isFavorite,
                  child: TextButton.icon(
                    onPressed: onFavoriteToggled,
                    icon: Icon(
                      isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 21,
                    ),
                    label: Text(
                      isFavorite ? l10n.commonSaved : l10n.commonSave,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isFavorite
                          ? colors.accent
                          : colors.textSecondary,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: property.isPublic
                      ? () => PropertyShareSheet.show(context, property)
                      : null,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                  label: Text(l10n.propertyShare),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    minimumSize: const Size(48, 48),
                  ),
                ),
                if (property.isPublic && onViewOnMap != null)
                  TextButton.icon(
                    onPressed: onViewOnMap,
                    icon: const Icon(Icons.map_outlined, size: 21),
                    label: Text(l10n.propertyViewOnMap),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
