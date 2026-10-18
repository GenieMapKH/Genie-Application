import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/presentation/property_labels.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/owner_display_name.dart';

/// Item card for Saved Properties screen matching Screenshot 1.
/// Explicitly omits the "Edit" button since saved properties may belong to other owners.
class SavedPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggled;

  const SavedPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.isFavorite = true,
    this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'saved_property_hero_${property.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: context.colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Property image gallery container matching PropertyItemCard
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PropertyImageGallery(imageUrls: property.imageUrls),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _TypePill(propertyType: property.propertyType),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _AnimatedFavoriteButton(
                            isFavorite: isFavorite,
                            onPressed: onFavoriteToggled,
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
                          PropertyFormat.money(property.finalPrice),
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          PropertyFormat.cardSpecLine(context.l10n, property),
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
                            ownerDisplayName(context.l10n, property.ownerName),
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
    );
  }
}

class _TypePill extends StatelessWidget {
  final String propertyType;

  const _TypePill({required this.propertyType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            PropertyFormat.typeIconPath(propertyType),
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(
              context.colors.textSecondary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            propertyValueLabel(context.l10n, propertyType),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onPressed;

  const _AnimatedFavoriteButton({required this.isFavorite, this.onPressed});

  @override
  State<_AnimatedFavoriteButton> createState() =>
      _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<_AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(covariant _AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward(from: 0.0);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(widget.isFavorite),
                size: 18,
                color: widget.isFavorite
                    ? context.colors.accent
                    : context.colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
