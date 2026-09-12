import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/utils/property_format.dart';

/// "Property Highlights" — the description with a Show more/less toggle, and
/// the days-listed / views / saves counters beneath it.
class PropertyHighlights extends StatefulWidget {
  final PropertyModel property;

  const PropertyHighlights({super.key, required this.property});

  /// Fallback copy for listings created before descriptions were required.
  static const String _fallbackDescription =
      'This land parcel is accurately mapped with verified boundaries and exact '
      'recorded coordinates, located in a fast-growing area near main '
      'infrastructure. It is ideal for residential development, a long-term '
      'investment, or a business project. The rectangular shape allows '
      'efficient planning and construction, while utilities such as electricity '
      'and water are already available nearby. Clear ownership documents and '
      'precise UTM location make this property easy to verify and trust.';

  @override
  State<PropertyHighlights> createState() => _PropertyHighlightsState();
}

class _PropertyHighlightsState extends State<PropertyHighlights> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.property.description?.trim().isNotEmpty == true
        ? widget.property.description!.trim()
        : PropertyHighlights._fallbackDescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Highlights',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
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
              color: const Color(0xFF4B5563),
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
                _expanded ? 'Show less' : 'Show more',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: const Color(0xFF111827),
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
        _Stat(value: PropertyFormat.daysListed(property), label: 'Genie'),
        const SizedBox(width: 24),
        // TODO(backend): no view counter exists yet; placeholder until it does.
        const _Stat(value: '1,688', label: 'Views'),
        const SizedBox(width: 24),
        _Stat(value: PropertyFormat.count(property.saveCount), label: 'Saves'),
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
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
