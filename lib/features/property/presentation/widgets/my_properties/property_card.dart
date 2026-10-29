import 'package:tilomnov/shared/widgets/media/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onOptionsTapped;

  /// Given the card's rectangle on screen, which the edit form grows out of.
  final ValueChanged<Rect>? onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onOptionsTapped,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusBgColor;
    Color statusTextColor;
    switch (property.status) {
      case 'Active':
        statusBgColor = const Color(0xFFD1FAE5);
        statusTextColor = const Color(0xFF059669);
        break;
      case 'Pending':
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFD97706);
        break;
      case 'Sold':
        statusBgColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFDC2626);
        break;
      case 'Draft':
      default:
        statusBgColor = context.colors.divider;
        statusTextColor = context.colors.textMuted;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Builder(
        builder: (cardContext) => GestureDetector(
          onTap: onTap == null
              ? null
              : () {
                  final box = cardContext.findRenderObject()! as RenderBox;
                  onTap!(box.localToGlobal(Offset.zero) & box.size);
                },
          onLongPress: onOptionsTapped,
          child: _buildCard(context, statusBgColor, statusTextColor),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color statusBgColor,
    Color statusTextColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: context.colors.divider,
                ),
                clipBehavior: Clip.antiAlias,
                child: property.cardImageUrls.isNotEmpty
                    ? AppNetworkImage(
                        url: property.cardImageUrls.first,
                        errorWidget: const PropertyImagePlaceholder(),
                      )
                    : Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: context.colors.textHint,
                          size: 48,
                        ),
                      ),
              ),
              // Property Type Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        property.propertyType == 'Land'
                            ? Icons.landscape
                            : Icons.home_outlined,
                        size: 14,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        propertyValueLabel(context.l10n, property.propertyType),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Favorite Icon
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: context.colors.textHint,
                  ),
                ),
              ),
              // Dots indicator
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: i == 0 ? 12 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          // Details Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      PropertyFormat.cardPrice(context.l10n, property),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        propertyValueLabel(context.l10n, property.status),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  PropertyFormat.cardSpecLine(context.l10n, property),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.propertyEdit,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        context,
                        PropertyFormat.count(property.contactCount),
                        context.l10n.propertyContacts,
                      ),
                      const SizedBox(width: 12),
                      _buildStatItem(
                        context,
                        PropertyFormat.count(property.viewCount),
                        context.l10n.propertyViews,
                      ),
                      const SizedBox(width: 12),
                      _buildStatItem(
                        context,
                        PropertyFormat.count(property.saveCount),
                        context.l10n.propertySaves,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String count, String label) {
    return Row(
      children: [
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
