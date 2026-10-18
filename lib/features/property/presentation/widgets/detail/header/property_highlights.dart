import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// "Property Highlights" — the description with a Show more/less toggle, and
/// the days-listed / views / saves counters beneath it.
class PropertyHighlights extends StatefulWidget {
  final PropertyModel property;

  const PropertyHighlights({super.key, required this.property});

  @override
  State<PropertyHighlights> createState() => _PropertyHighlightsState();
}

class _PropertyHighlightsState extends State<PropertyHighlights> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.property.description?.trim().isNotEmpty == true
        ? widget.property.description!.trim()
        // Fallback copy for listings created before descriptions were
        // required.
        : context.l10n.propertyFallbackDescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.propertyPropertyHighlights,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Text(
            description,
            maxLines: _expanded ? null : 5,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w400,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(
                _expanded
                    ? context.l10n.propertyShowLess
                    : context.l10n.propertyShowMore,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: context.colors.textPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StatsRow(property: widget.property),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PropertyModel property;

  const _StatsRow({required this.property});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(
          value: context.l10n.propertyDaysCount(property.daysListed),
          label: context.l10n.propertyGenie,
        ),
        const SizedBox(width: 24),
        // TODO(backend): no view counter exists yet; placeholder until it does.
        _Stat(value: '1,688', label: context.l10n.propertyViews),
        const SizedBox(width: 24),
        _Stat(
          value: PropertyFormat.count(property.saveCount),
          label: context.l10n.propertySaves,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.colors.textMuted,
          ),
        ),
      ],
    );
  }
}
