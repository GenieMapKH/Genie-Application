import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:genie/features/property/utils/property_format.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

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
                _expanded ? 'Show less' : 'Show more',
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

/// The counts come from the server when the listing was loaded. Saving or
/// unsaving it here moves the saves count straight away.
class _StatsRow extends ConsumerStatefulWidget {
  final PropertyModel property;

  const _StatsRow({required this.property});

  @override
  ConsumerState<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends ConsumerState<_StatsRow> {
  /// Whether the user had saved the listing when the counts were loaded;
  /// unknown until their saved list has loaded.
  bool? _savedAtLoad;

  int _saveCount() {
    final property = widget.property;
    final saved = ref.watch(savedPropertiesProvider).valueOrNull;
    if (saved == null) return property.saveCount;
    final savedNow = saved.any((p) => p.id == property.id);
    _savedAtLoad ??= savedNow;
    final change = (savedNow ? 1 : 0) - (_savedAtLoad! ? 1 : 0);
    return (property.saveCount + change).clamp(0, 1 << 31);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return Row(
      children: [
        _Stat(
          value: PropertyFormat.daysListed(property),
          label: context.l10n.propertyGenie,
        ),
        const SizedBox(width: 24),
        _Stat(
          value: PropertyFormat.count(property.viewCount),
          label: context.l10n.propertyViews,
        ),
        const SizedBox(width: 24),
        _Stat(
          value: PropertyFormat.count(_saveCount()),
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
