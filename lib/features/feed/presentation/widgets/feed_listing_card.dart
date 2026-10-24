import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/widgets/saved_property_card.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/owner_display_name.dart';
import 'package:genie/shared/widgets/media/user_avatar.dart';

/// One listing in the feed: who posted it and when, then the listing card.
class FeedListingCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavorite;
  final VoidCallback onOpen;

  /// Opens the owner's profile, out of their avatar's on-screen rectangle.
  final ValueChanged<Rect> onOpenOwner;
  final VoidCallback onFavoriteToggled;

  const FeedListingCard({
    super.key,
    required this.property,
    required this.isFavorite,
    required this.onOpen,
    required this.onOpenOwner,
    required this.onFavoriteToggled,
  });

  /// Tall enough for a wide photo above the price and details.
  static const double _cardHeight = 320;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PostedBy(property: property, onTap: onOpenOwner),
        const SizedBox(height: 10),
        SizedBox(
          height: _cardHeight,
          child: SavedPropertyCard(
            property: property,
            isFavorite: isFavorite,
            onTap: onOpen,
            onFavoriteToggled: onFavoriteToggled,
          ),
        ),
      ],
    );
  }
}

/// The owner's picture and name (opening their profile), and the day listed.
class _PostedBy extends StatefulWidget {
  final PropertyModel property;

  /// Gets the avatar's on-screen rectangle.
  final ValueChanged<Rect> onTap;

  const _PostedBy({required this.property, required this.onTap});

  @override
  State<_PostedBy> createState() => _PostedByState();
}

class _PostedByState extends State<_PostedBy> {
  final _avatarKey = GlobalKey();

  void _onTap() {
    final box = _avatarKey.currentContext!.findRenderObject()! as RenderBox;
    widget.onTap(box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final colors = context.colors;
    final l10n = context.l10n;
    final name = ownerDisplayName(l10n, property.ownerName);
    final listed = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format((property.publishedAt ?? property.createdAt).toLocal());

    return InkWell(
      onTap: _onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            UserAvatar(
              key: _avatarKey,
              name: name,
              avatarUrl: property.ownerAvatarUrl,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.feedListedOn(listed),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (property.recentPreviousPrice() case final before?)
              _PriceDropBadge(previousPrice: before),
          ],
        ),
      ),
    );
  }
}

/// "Price dropped", and what a buyer paid before it.
class _PriceDropBadge extends StatelessWidget {
  final double previousPrice;

  const _PriceDropBadge({required this.previousPrice});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_down, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.feedPriceDropped,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                PropertyFormat.money(previousPrice),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
