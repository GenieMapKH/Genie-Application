// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'add_property_page.dart';
import 'add_property_page_layout.dart';
import 'add_property_page_logic.dart';
import 'add_property_page_forms_dynamic.dart';

extension AddPropertyPageFormsBase on AddPropertyPageState {
  Widget buildLandSizeField({bool isLandType = false}) {
    return Column(
      key: landSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: isLandType ? 'Size' : 'Land Size',
              required: true,
              hasError:
                  hasAttemptedSubmit &&
                  landSizeController.text.trim().isEmpty,
            ),
            isLandType
                ? InkWell(
                    onTap: () {},
                    child: Text(
                      'Auto from map',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Total land area of the property',
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
          controller: landSizeController,
          decoration: defaultPropertyInputDecoration(
            isLandType ? 'Size Area' : 'Enter land size',
            hasError:
                hasAttemptedSubmit && landSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget buildTitleTypeField() {
    return buildDropdown(
      label: 'Title Type',
      required: false,
      value: selectedTitleType,
      items: ['Hard Title', 'Soft Title', 'Other'],
      onChanged: (val) {
        if (val != null) setState(() => selectedTitleType = val);
      },
    );
  }

  Widget buildBuildingSizeField() {
    return Column(
      key: buildingSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: 'Building Size',
              required: true,
              hasError:
                  hasAttemptedSubmit &&
                  buildingSizeController.text.trim().isEmpty,
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
                  'Total built-up area',
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
          controller: buildingSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter building size',
            hasError:
                hasAttemptedSubmit &&
                buildingSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget buildUnitSizeField() {
    return Column(
      key: unitSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: 'Unit Size',
              required: true,
              hasError:
                  hasAttemptedSubmit &&
                  unitSizeController.text.trim().isEmpty,
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
                  'Total usable area of the unit',
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
          controller: unitSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter unit size',
            hasError:
                hasAttemptedSubmit && unitSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget buildMaintenanceFeeField() {
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
          controller: maintenanceFeeController,
          decoration: defaultPropertyInputDecoration(
            'Monthly maintenance fee (USD)',
          ),
        ),
      ],
    );
  }

  Widget buildBedroomsField({bool isCondo = false}) {
    List<String> items = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'];
    if (isCondo) {
      items.insert(0, 'Studio');
    } else {
      items.insert(0, '0');
    }
    return buildDropdown(
      label: 'Bedrooms',
      required: false,
      value: selectedBedrooms,
      hintText: 'Number of bedrooms',
      items: items,
      onChanged: (val) => setState(() => selectedBedrooms = val),
    );
  }

  Widget buildBathroomsField() {
    return buildDropdown(
      label: 'Bathrooms',
      required: false,
      value: selectedBathrooms,
      hintText: 'Number of bathrooms',
      items: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => selectedBathrooms = val),
    );
  }

  Widget buildFloorsField() {
    return buildDropdown(
      label: 'Floors',
      required: false,
      value: selectedFloors,
      hintText: 'Total floors (e.g. 2)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => selectedFloors = val),
    );
  }

  Widget buildNumberofFloorsField() {
    return buildDropdown(
      label: 'Number of Floors',
      required: false,
      value: selectedFloors,
      hintText: 'Number of Floors',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => selectedFloors = val),
    );
  }

  Widget buildFloorNumberField() {
    return buildDropdown(
      label: 'Floor Number',
      required: false,
      value: selectedFloorNumber,
      hintText: 'Enter floor number (e.g. 12)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => selectedFloorNumber = val),
    );
  }

  Widget buildTotalFloorsField() {
    return buildDropdown(
      label: 'Total Floors',
      required: false,
      value: selectedFloors,
      hintText: 'Total floors in building',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => selectedFloors = val),
    );
  }

  Widget buildParkingField() {
    return buildDropdown(
      label: 'Parking',
      required: false,
      value: selectedParking,
      hintText: 'Select parking',
      items: ['Yes', 'No'],
      onChanged: (val) => setState(() => selectedParking = val),
    );
  }

  Widget buildFurnishedField() {
    return buildDropdown(
      label: 'Furnished',
      required: false,
      value: selectedFurnished,
      hintText: 'Select furnished',
      items: ['Unfurnished', 'Fully Furnished', 'Electrical appliances'],
      onChanged: (val) => setState(() => selectedFurnished = val),
    );
  }

  Widget buildBuildingTypeField() {
    return buildDropdown(
      label: 'Building Type',
      required: false,
      value: selectedBuildingType,
      hintText: 'Select building type',
      items: [
        'Commercial Building',
        'Office Building',
        'Mixed-use',
        'Retail Building',
        'Warehouse',
      ],
      onChanged: (val) => setState(() => selectedBuildingType = val),
    );
  }

  Widget buildTotalUnitsField() {
    return buildDropdown(
      label: 'Total Units',
      required: false,
      value: selectedTotalUnits,
      hintText: 'Number of units',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => selectedTotalUnits = val),
    );
  }

  Widget buildBalconyField() {
    return buildDropdown(
      label: 'Balcony',
      required: false,
      value: selectedBalcony,
      hintText: 'Select balcony',
      items: ['Yes', 'No'],
      onChanged: (val) => setState(() => selectedBalcony = val),
    );
  }

  Widget buildCompletionStatusField() {
    return buildDropdown(
      label: 'Completion Status',
      required: false,
      value: selectedCompletionStatus,
      hintText: 'Select Status',
      items: ['Off-plan', 'Under Construction', 'Completed'],
      onChanged: (val) => setState(() => selectedCompletionStatus = val),
    );
  }

  Widget buildViewTypeField() {
    return buildDropdown(
      label: 'View Type',
      required: false,
      value: selectedViewType,
      hintText: 'Select view type',
      items: ['City View', 'River View', 'Garden View', 'Pool View', 'No View'],
      onChanged: (val) => setState(() => selectedViewType = val),
    );
  }

  Widget buildProjectTypeField() {
    return buildDropdown(
      label: 'Project Type',
      required: false,
      value: selectedProjectType,
      hintText: 'Select project type',
      items: ['Borey', 'Condo', 'Commercial', 'Mixed-use', 'Land Subdivision'],
      onChanged: (val) => setState(() => selectedProjectType = val),
    );
  }

  Widget buildBoreyCompletionStatusField() {
    return buildDropdown(
      label: 'Completion Status',
      required: false,
      value: selectedCompletionStatus,
      hintText: 'Select status',
      items: [
        'Pre-launch',
        'Under Construction',
        '50% Completed',
        '80% Completed',
        'Completed',
      ],
      onChanged: (val) => setState(() => selectedCompletionStatus = val),
    );
  }

  Widget buildLeaseRemainingField() {
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
                controller: leaseRemainingController,
                decoration: defaultPropertyInputDecoration('Duration'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: selectedLeaseUnit ?? 'Months',
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
                onChanged: (val) => setState(() => selectedLeaseUnit = val),
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

  Widget buildDropdown({
    required String label,
    required bool required,
    required String? value,
    String? hintText,
    required List<String> items,
    required Function(String?) onChanged,
    bool hasError = false,
    Key? focusKey,
  }) {
    return PropertyDropdown(
      label: label,
      required: required,
      value: value,
      hintText: hintText,
      items: items,
      onChanged: onChanged,
      hasError: hasError,
      focusKey: focusKey,
    );
  }
}
