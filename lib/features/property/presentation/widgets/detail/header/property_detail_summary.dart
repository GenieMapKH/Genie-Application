import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/features/property/presentation/property_labels.dart';

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
        if (property.hasDiscount) ...[
          _PriceCutBadge(property: property),
          const SizedBox(height: 10),
          // The asking price, crossed out above what the buyer pays.
          Text(
            PropertyFormat.money(property.askingPrice),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.colors.textMuted,
              decoration: TextDecoration.lineThrough,
              decorationColor: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          PropertyFormat.money(property.finalPrice),
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

/// "Price cut: 20%" or "Price cut: $ 5,000", as the seller entered it.
class _PriceCutBadge extends StatelessWidget {
  final PropertyModel property;

  const _PriceCutBadge({required this.property});

  @override
  Widget build(BuildContext context) {
    final value = property.discountValue!;
    final amount = property.discountType == 'percent'
        ? '${PropertyFormat.size(value)}%'
        : PropertyFormat.money(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.dangerSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.l10n.propertyPriceCut(amount),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.colors.onDangerSoft,
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
        context.l10n.propertyBedroomCount(property.bedrooms!),
      ));
    }
    if (property.bathrooms != null && property.bathrooms! > 0) {
      specs.add((
        Icons.bathtub_outlined,
        context.l10n.propertyBathroomCount(property.bathrooms!),
      ));
    }

    final size = property.displaySize;
    if (size != null) {
      specs.add((Icons.straighten, '${PropertyFormat.size(size)} m²'));
    }

    if (specs.isEmpty) {
      return Text(
        context.l10n.propertyTypeForSale(
          propertyValueLabel(context.l10n, property.propertyType),
        ),
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
