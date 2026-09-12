import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/tactile_button.dart';

class PropertyTypeFilters extends StatefulWidget {
  const PropertyTypeFilters({super.key});

  @override
  State<PropertyTypeFilters> createState() => _PropertyTypeFiltersState();
}

class _PropertyTypeFiltersState extends State<PropertyTypeFilters> {
  bool _isListingTypeOpen = false;
  String? _selectedListingType;
  String? _selectedPropertyType;

  static const List<Map<String, String>> _propertyTypes = [
    {'name': 'House', 'iconPath': 'assets/icons/property_house.svg'},
    {'name': 'Land', 'iconPath': 'assets/icons/property_land.svg'},
    {'name': 'Condo', 'iconPath': 'assets/icons/property_condo.svg'},
    {'name': 'Building', 'iconPath': 'assets/icons/property_building.svg'},
    {'name': 'Borey', 'iconPath': 'assets/icons/property_borey.svg'},
    {'name': 'Business', 'iconPath': 'assets/icons/property_business.svg'},
    {'name': 'Warehouse', 'iconPath': 'assets/icons/property_warehouse.svg'},
  ];

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
              ..._propertyTypes.map(
                (type) =>
                    _buildPropertyTypePill(type['name']!, type['iconPath']!),
              ),
              const SizedBox(width: 8), // End padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingTypeSelector() {
    final bool isListingTypeSelected = _selectedListingType != null;
    return TactileButton(
      onPressed: () {
        setState(() {
          _isListingTypeOpen = !_isListingTypeOpen;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isListingTypeSelected
                ? const Color(0xFF3E49C7)
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
                  ? const Color(0xFF3E49C7)
                  : const Color(0xFF6B7280),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _selectedListingType ?? 'Listing Type',
              style: GoogleFonts.inter(
                color: isListingTypeSelected
                    ? const Color(0xFF3E49C7)
                    : const Color(0xFF4B5563),
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
                  ? const Color(0xFF3E49C7)
                  : const Color(0xFF6B7280),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownPill(String text) {
    final isSelected = _selectedListingType == text;
    return TactileButton(
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedListingType = null;
          } else {
            _selectedListingType = text;
          }
          _isListingTypeOpen = false; // Auto close on select
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF3E49C7) : Colors.transparent,
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
          text,
          style: GoogleFonts.inter(
            color: isSelected
                ? const Color(0xFF3E49C7)
                : const Color(0xFF4B5563),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyTypePill(String text, String iconPath) {
    final isSelected = _selectedPropertyType == text;
    return TactileButton(
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedPropertyType = null;
          } else {
            _selectedPropertyType = text;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF3E49C7) : Colors.transparent,
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
                isSelected ? const Color(0xFF3E49C7) : const Color(0xFF6B7280),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.inter(
                color: isSelected
                    ? const Color(0xFF3E49C7)
                    : const Color(0xFF4B5563),
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
