import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:genie/features/property/presentation/screens/add_property_page.dart';

class MaintenanceFeeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;

  const MaintenanceFeeFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PropertySectionTitle(
              title: 'Maintenance Fee',
              required: false,
            ),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  'Building management fee per month',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: state.maintenanceFeeController,
          decoration: defaultPropertyInputDecoration(
            'Monthly maintenance fee (USD)',
          ),
        ),
      ],
    );
  }
}

class LeaseRemainingFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  final ValueChanged<String?> onUnitChanged;

  const LeaseRemainingFieldWidget({
    super.key,
    required this.state,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PropertySectionTitle(
              title: 'Lease Remaining',
              required: false,
            ),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  'Remaining contract duration with landlord',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: state.leaseRemainingController,
                decoration: defaultPropertyInputDecoration('Duration'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: state.selectedLeaseUnit ?? 'Months',
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF9CA3AF),
                ),
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                decoration: defaultPropertyInputDecoration('Select unit'),
                onChanged: onUnitChanged,
                items: ['Months', 'Years'].map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DefaultPriceListingSettingsWidget extends StatelessWidget {
  final AddPropertyPageState state;
  final ValueChanged<String?> onListingSettingChanged;

  const DefaultPriceListingSettingsWidget({
    super.key,
    required this.state,
    required this.onListingSettingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PropertyTextField(
            label: 'Price',
            required: true,
            controller: state.priceController,
            hintText: 'Enter selling price (USD)',
            hasError:
                state.hasAttemptedSubmit &&
                state.priceController.text.trim().isEmpty,
            focusKey: state.priceKey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PropertyDropdown(
            label: 'Listing Settings',
            required: true,
            value: state.selectedListingSetting,
            items: const ['Sale', 'Rent', 'To Let'],
            hasError:
                state.hasAttemptedSubmit &&
                state.selectedListingSetting.isEmpty,
            focusKey: state.listingSettingsKey,
            onChanged: onListingSettingChanged,
          ),
        ),
      ],
    );
  }
}
