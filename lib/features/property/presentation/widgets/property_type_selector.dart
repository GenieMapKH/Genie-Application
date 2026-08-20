import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class PropertyTypeSelector extends StatelessWidget {
  final String selectedPropertyType;
  final ValueChanged<String> onChanged;

  const PropertyTypeSelector({
    super.key,
    required this.selectedPropertyType,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> _propertyTypes = [
    {'name': 'Land', 'iconPath': 'assets/icons/property_land.svg'},
    {'name': 'House', 'iconPath': 'assets/icons/property_house.svg'},
    {'name': 'Building', 'iconPath': 'assets/icons/property_building.svg'},
    {'name': 'Condo', 'iconPath': 'assets/icons/property_condo.svg'},
    {'name': 'Borey', 'iconPath': 'assets/icons/property_borey.svg'},
    {
      'name': 'Business for Sale',
      'iconPath': 'assets/icons/property_business.svg',
    },
    {'name': 'Warehouse', 'iconPath': 'assets/icons/property_warehouse.svg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _propertyTypes.map((type) {
        final isSelected = selectedPropertyType == type['name'];
        return GestureDetector(
          onTap: () => onChanged(type['name']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width:
                (MediaQuery.sizeOf(context).width - 32 - 24) / 3, // 3 columns
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF5B5FEF).withValues(alpha: 0.05)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5B5FEF)
                    : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  type['iconPath'],
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? const Color(0xFF5B5FEF)
                        : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  type['name'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? const Color(0xFF5B5FEF)
                        : const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
