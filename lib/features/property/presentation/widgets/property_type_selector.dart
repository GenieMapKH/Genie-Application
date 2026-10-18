import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/property/presentation/property_labels.dart';
import 'package:genie/l10n/l10n.dart';

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
                  ? context.colors.accent.withValues(alpha: 0.05)
                  : context.colors.surface,
              border: Border.all(
                color: isSelected
                    ? context.colors.accent
                    : context.colors.border,
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
                        ? context.colors.accent
                        : context.colors.textMuted,
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  propertyValueLabel(context.l10n, type['name']),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? context.colors.accent
                        : context.colors.textMuted,
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
