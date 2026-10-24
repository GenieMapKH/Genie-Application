import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/saved_property_ids_provider.dart';
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
    final description = widget.property.description?.trim() ?? '';
    final hasDescription = description.isNotEmpty;

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
        if (hasDescription) ..._descriptionWithToggle(context, description),
        const SizedBox(height: 16),
        _StatsRow(property: widget.property),
      ],
    );
  }

  List<Widget> _descriptionWithToggle(
    BuildContext context,
    String description,
  ) {
    return [
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
    ];
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
    final saved = ref.watch(savedPropertyIdsProvider).valueOrNull;
    if (saved == null) return property.saveCount;
    final savedNow = saved.contains(property.id);
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
          value: context.l10n.propertyDaysCount(property.daysListed),
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
