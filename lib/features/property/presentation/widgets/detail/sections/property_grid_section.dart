import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/core/theme/app_colors.dart';

/// A two-column grid of compact listing tiles, used for both the "Similar
/// Property" and "Property for you" sections of the detail sheet.
class PropertyGridSection extends StatelessWidget {
  final String title;
  final List<PropertyModel> properties;
  final void Function(PropertyModel property) onPropertyTapped;

  const PropertyGridSection({
    super.key,
    required this.title,
    required this.properties,
    required this.onPropertyTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: properties.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final property = properties[index];
            return _PropertyTile(
              property: property,
              onTap: () => onPropertyTapped(property),
            );
          },
        ),
      ],
    );
  }
}

class _PropertyTile extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  const _PropertyTile({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                PropertyImageGallery(
                  imageUrls: property.imageUrls,
                  borderRadius: BorderRadius.circular(10),
                  showIndicator: false,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            PropertyFormat.money(property.finalPrice),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            PropertyFormat.cardSpecLine(property),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            property.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Listing by: ${property.ownerName ?? 'Property Owner'}',
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
    );
  }
}
