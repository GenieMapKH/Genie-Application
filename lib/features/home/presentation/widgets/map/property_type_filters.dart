import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';

import 'package:genie/shared/widgets/buttons/tactile_button.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/presentation/property_labels.dart';
import 'package:genie/l10n/l10n.dart';

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
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Listing Type Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildListingTypeSelector(),
                  if (_isListingTypeOpen) ...[
                    const SizedBox(height: 8),
                    _buildDropdownPill('Sale'),
                    const SizedBox(height: 8),
                    _buildDropdownPill('Rent'),
                    const SizedBox(height: 8),
                    _buildDropdownPill('To Let'),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              // Property Types
              for (final (value, iconPath) in _propertyTypes)
                _buildPropertyTypePill(_typeLabel(value), value, iconPath),
              const SizedBox(width: 8), // End padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingTypeSelector() {
    final selectedListingType = _filter.listingType;
    final bool isListingTypeSelected = selectedListingType != null;
    return TactileButton(
      onPressed: () {
        setState(() {
          _isListingTypeOpen = !_isListingTypeOpen;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(
            color: isListingTypeSelected
                ? context.colors.primaryStrong
                : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isListingTypeOpen ? Icons.cancel : Icons.maps_home_work_outlined,
              color: isListingTypeSelected
                  ? context.colors.primaryStrong
                  : context.colors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              selectedListingType == null
                  ? context.l10n.listingTypeTitle
                  : propertyValueLabel(context.l10n, selectedListingType),
              style: GoogleFonts.inter(
                color: isListingTypeSelected
                    ? context.colors.primaryStrong
                    : context.colors.textSecondary,
                fontWeight: isListingTypeSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isListingTypeOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: isListingTypeSelected
                  ? context.colors.primaryStrong
                  : context.colors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPill(String text) {
    final isSelected = _filter.listingType == text;
    return TactileButton(
      onPressed: () {
        _update((filter) => filter.toggleListing(text));
        setState(() => _isListingTypeOpen = false); // Auto close on select
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isSelected
                ? context.colors.primaryStrong
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          propertyValueLabel(context.l10n, text),
          style: GoogleFonts.inter(
            color: isSelected
                ? context.colors.primaryStrong
                : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyTypePill(String text, String value, String iconPath) {
    final isSelected = _filter.propertyType == value;
    return TactileButton(
      onPressed: () => _update((filter) => filter.toggleType(value)),
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isSelected
                ? context.colors.primaryStrong
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                isSelected
                    ? context.colors.primaryStrong
                    : context.colors.textMuted,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.inter(
                color: isSelected
                    ? context.colors.primaryStrong
                    : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
