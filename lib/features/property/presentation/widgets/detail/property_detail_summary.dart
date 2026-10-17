import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/core/theme/app_colors.dart';

/// Price, spec row and location — the block that sits directly under the photo
/// gallery in the detail sheet and stays visible as the sheet expands.
class PropertyDetailSummary extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailSummary({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO(backend): no previousPrice column yet, so the reduction is fixed.
        const _PriceCutBadge(percentage: 20),
        const SizedBox(height: 10),
        Text(
          PropertyFormat.price(property.price),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _SpecRow(property: property),
        const SizedBox(height: 8),
        Text(
          property.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PriceCutBadge extends StatelessWidget {
  final int percentage;

  const _PriceCutBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Price Cut: $percentage%',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFDC2626),
        ),
      ),
    );
  }
}

/// `2 Beds · 2 Baths · 83.5 m²` with a small icon per item.
class _SpecRow extends StatelessWidget {
  final PropertyModel property;

  const _SpecRow({required this.property});

  @override
  Widget build(BuildContext context) {
    final specs = <(IconData, String)>[];

    if (property.bedrooms != null && property.bedrooms! > 0) {
      specs.add((
        Icons.bed_outlined,
        PropertyFormat.bedroomLabel(property.bedrooms!),
      ));
    }
    if (property.bathrooms != null && property.bathrooms! > 0) {
      specs.add((
        Icons.bathtub_outlined,
        PropertyFormat.bathroomLabel(property.bathrooms!),
      ));
    }

    final size = property.displaySize;
    if (size != null) {
      specs.add((Icons.straighten, '${PropertyFormat.size(size)} m²'));
    }

    if (specs.isEmpty) {
      return Text(
        '${property.propertyType} for sale',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.colors.textPrimary,
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: specs
          .map(
            (spec) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(spec.$1, size: 16, color: context.colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  spec.$2,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
