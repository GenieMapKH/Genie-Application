import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/map_capsule.dart';
import 'package:tilomnov/features/property/presentation/view_models/map_property_filter.dart';

import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// The pills under the map's search bar: one listing type and one property
/// type at a time, kept in [mapPropertyFilterProvider], which the map obeys.
class PropertyTypeFilters extends ConsumerStatefulWidget {
  const PropertyTypeFilters({super.key});

  @override
  ConsumerState<PropertyTypeFilters> createState() =>
      _PropertyTypeFiltersState();
}

class _PropertyTypeFiltersState extends ConsumerState<PropertyTypeFilters> {
  bool _isListingTypeOpen = false;

  MapPropertyFilter get _filter => ref.watch(mapPropertyFilterProvider);

  void _update(MapPropertyFilter Function(MapPropertyFilter) change) {
    ref.read(mapPropertyFilterProvider.notifier).update(change);
  }

  /// Value stored, icon. The pill shows the value in the user's language.
  static const List<(String, String)> _propertyTypes = [
    ('House', 'assets/icons/property_house.svg'),
    ('Land', 'assets/icons/property_land.svg'),
    ('Condo', 'assets/icons/property_condo.svg'),
    ('Building', 'assets/icons/property_building.svg'),
    ('Borey', 'assets/icons/property_borey.svg'),
    ('Business for Sale', 'assets/icons/property_business.svg'),
    ('Warehouse', 'assets/icons/property_warehouse.svg'),
  ];

  /// The pill is short: "Business", not "Business for Sale".
  String _typeLabel(String value) => value == 'Business for Sale'
      ? context.l10n.propertyTypeBusinessShort
      : propertyValueLabel(context.l10n, value);

  @override
  Widget build(BuildContext context) {
    // The parent leaves 16 on both sides, the same as the search bar and the
    // round buttons above, so the row starts and stops 16 from each edge.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      // A horizontal scroll view is only as wide as its content when that
      // fits, which clipped the pills short of the screen edge on a tablet.
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          child: Row(
            spacing: _gap,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Listing Type Column
              Column(
                spacing: _gap,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildListingTypeSelector(),
                  if (_isListingTypeOpen) ...[
                    _buildDropdownPill('Sale'),
                    _buildDropdownPill('Rent'),
                    _buildDropdownPill('To Let'),
                    _buildDropdownPill('Takeover Payments'),
                  ],
                ],
              ),
              // Property Types
              for (final (value, iconPath) in _propertyTypes)
                _buildPropertyTypePill(_typeLabel(value), value, iconPath),
            ],
          ),
        ),
      ),
    );
  }

  /// The space between pills, the same as between the buttons above them.
  static const _gap = 8.0;

  bool get _glass => watchGlassNavigation(ref, context);

  /// A pill's icon and label: the accent when picked; otherwise quiet on a
  /// solid surface and plain text colour over glass, as the round buttons do.
  Color _ink(bool selected, {required Color solid}) {
    if (selected) return context.colors.primaryStrong;
    return _glass ? context.colors.textPrimary : solid;
  }

  /// One listing type by name; the filter page's "For rent" (Rent and To Let)
  /// as that.
  String? _listingLabel(List<String> types) {
    if (types.isEmpty) return null;
    if (types.length == 1) return propertyValueLabel(context.l10n, types.first);
    if (_filter.isForSale) return context.l10n.filterForSale;
    return _filter.isForRent ? context.l10n.filterForRent : null;
  }

  Widget _buildListingTypeSelector() {
    final selectedLabel = _listingLabel(_filter.listingTypes);
    final bool isListingTypeSelected = _filter.listingTypes.isNotEmpty;
    final ink = _ink(isListingTypeSelected, solid: context.colors.textMuted);
    return TactileButton(
      onPressed: () {
        setState(() {
          _isListingTypeOpen = !_isListingTypeOpen;
        });
      },
      child: _FilterCapsule(
        outline: isListingTypeSelected ? context.colors.primaryStrong : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isListingTypeOpen
                  ? LucideIcons.circleX
                  : LucideIcons.mapPinHouse,
              color: ink,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              selectedLabel ?? context.l10n.listingTypeTitle,
              style: _labelStyle(isListingTypeSelected),
            ),
            const SizedBox(width: 4),
            Icon(
              _isListingTypeOpen
                  ? LucideIcons.chevronUp
                  : LucideIcons.chevronDown,
              color: ink,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPill(String text) {
    final isSelected = MapPropertyFilter.listingEquals(_filter.listingTypes, [
      text,
    ]);
    return TactileButton(
      onPressed: () {
        _update((filter) => filter.toggleListing(text));
        setState(() => _isListingTypeOpen = false); // Auto close on select
      },
      child: _FilterCapsule(
        outline: isSelected ? context.colors.primaryStrong : null,
        child: Text(
          propertyValueLabel(context.l10n, text),
          style: _labelStyle(isSelected),
        ),
      ),
    );
  }

  Widget _buildPropertyTypePill(String text, String value, String iconPath) {
    final isSelected = _filter.propertyType == value;
    return TactileButton(
      onPressed: () => _update((filter) => filter.toggleType(value)),
      child: _FilterCapsule(
        outline: isSelected ? context.colors.primaryStrong : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TintedSvg(
              iconPath,
              width: 14,
              height: 14,
              color: _ink(isSelected, solid: context.colors.textMuted),
            ),
            const SizedBox(width: 6),
            Text(text, style: _labelStyle(isSelected)),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle(bool selected) => GoogleFonts.inter(
    color: _ink(selected, solid: context.colors.textSecondary),
    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    fontSize: 13,
  );
}

/// A smaller visible pill with a full-height touch target.
class _FilterCapsule extends StatelessWidget {
  final Color? outline;
  final Widget child;

  const _FilterCapsule({required this.outline, required this.child});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: Align(
      widthFactor: 1,
      heightFactor: 1,
      child: MapCapsule(
        shadowed: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        outline: outline,
        child: child,
      ),
    ),
  );
}
