// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'add_property_page.dart';

extension AddPropertyPageFormsBase on _AddPropertyPageState {
  Widget _buildLandSizeField({bool isLandType = false}) {
    return Column(
      key: _landSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(title: 
              isLandType ? 'Size' : 'Land Size', required: true, hasError: _hasAttemptedSubmit &&
                  _landSizeController.text.trim().isEmpty,
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
          controller: _landSizeController,
          decoration: defaultPropertyInputDecoration(
            isLandType ? 'Size Area' : 'Enter land size',
            hasError:
                _hasAttemptedSubmit && _landSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleTypeField() {
    return _buildDropdown(
      label: 'Title Type',
      required: false,
      value: _selectedTitleType,
      items: ['Hard Title', 'Soft Title', 'Other'],
      onChanged: (val) {
        if (val != null) setState(() => _selectedTitleType = val);
      },
    );
  }

  Widget _buildBuildingSizeField() {
    return Column(
      key: _buildingSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(title: 
              'Building Size', required: true, hasError: _hasAttemptedSubmit &&
                  _buildingSizeController.text.trim().isEmpty,
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
          controller: _buildingSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter building size',
            hasError:
                _hasAttemptedSubmit &&
                _buildingSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSizeField() {
    return Column(
      key: _unitSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(title: 
              'Unit Size', required: true, hasError: _hasAttemptedSubmit &&
                  _unitSizeController.text.trim().isEmpty,
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
          controller: _unitSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter unit size',
            hasError:
                _hasAttemptedSubmit && _unitSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceFeeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PropertySectionTitle(title: 'Maintenance Fee', required: false),
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
          controller: _maintenanceFeeController,
          decoration: defaultPropertyInputDecoration(
            'Monthly maintenance fee (USD)',
          ),
        ),
      ],
    );
  }

  Widget _buildBedroomsField({bool isCondo = false}) {
    List<String> items = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'];
    if (isCondo) {
      items.insert(0, 'Studio');
    } else {
      items.insert(0, '0');
    }
    return _buildDropdown(
      label: 'Bedrooms',
      required: false,
      value: _selectedBedrooms,
      hintText: 'Number of bedrooms',
      items: items,
      onChanged: (val) => setState(() => _selectedBedrooms = val),
    );
  }

  Widget _buildBathroomsField() {
    return _buildDropdown(
      label: 'Bathrooms',
      required: false,
      value: _selectedBathrooms,
      hintText: 'Number of bathrooms',
      items: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedBathrooms = val),
    );
  }

  Widget _buildFloorsField() {
    return _buildDropdown(
      label: 'Floors',
      required: false,
      value: _selectedFloors,
      hintText: 'Total floors (e.g. 2)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloors = val),
    );
  }

  Widget _buildNumberofFloorsField() {
    return _buildDropdown(
      label: 'Number of Floors',
      required: false,
      value: _selectedFloors,
      hintText: 'Number of Floors',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloors = val),
    );
  }

  Widget _buildFloorNumberField() {
    return _buildDropdown(
      label: 'Floor Number',
      required: false,
      value: _selectedFloorNumber,
      hintText: 'Enter floor number (e.g. 12)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloorNumber = val),
    );
  }

  Widget _buildTotalFloorsField() {
    return _buildDropdown(
      label: 'Total Floors',
      required: false,
      value: _selectedFloors,
      hintText: 'Total floors in building',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloors = val),
    );
  }

  Widget _buildParkingField() {
    return _buildDropdown(
      label: 'Parking',
      required: false,
      value: _selectedParking,
      hintText: 'Select parking',
      items: ['Yes', 'No'],
      onChanged: (val) => setState(() => _selectedParking = val),
    );
  }

  Widget _buildFurnishedField() {
    return _buildDropdown(
      label: 'Furnished',
      required: false,
      value: _selectedFurnished,
      hintText: 'Select furnished',
      items: ['Unfurnished', 'Fully Furnished', 'Electrical appliances'],
      onChanged: (val) => setState(() => _selectedFurnished = val),
    );
  }

  Widget _buildBuildingTypeField() {
    return _buildDropdown(
      label: 'Building Type',
      required: false,
      value: _selectedBuildingType,
      hintText: 'Select building type',
      items: [
        'Commercial Building',
        'Office Building',
        'Mixed-use',
        'Retail Building',
        'Warehouse',
      ],
      onChanged: (val) => setState(() => _selectedBuildingType = val),
    );
  }

  Widget _buildTotalUnitsField() {
    return _buildDropdown(
      label: 'Total Units',
      required: false,
      value: _selectedTotalUnits,
      hintText: 'Number of units',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedTotalUnits = val),
    );
  }

  Widget _buildBalconyField() {
    return _buildDropdown(
      label: 'Balcony',
      required: false,
      value: _selectedBalcony,
      hintText: 'Select balcony',
      items: ['Yes', 'No'],
      onChanged: (val) => setState(() => _selectedBalcony = val),
    );
  }

  Widget _buildCompletionStatusField() {
    return _buildDropdown(
      label: 'Completion Status',
      required: false,
      value: _selectedCompletionStatus,
      hintText: 'Select Status',
      items: ['Off-plan', 'Under Construction', 'Completed'],
      onChanged: (val) => setState(() => _selectedCompletionStatus = val),
    );
  }

  Widget _buildViewTypeField() {
    return _buildDropdown(
      label: 'View Type',
      required: false,
      value: _selectedViewType,
      hintText: 'Select view type',
      items: ['City View', 'River View', 'Garden View', 'Pool View', 'No View'],
      onChanged: (val) => setState(() => _selectedViewType = val),
    );
  }

  Widget _buildProjectTypeField() {
    return _buildDropdown(
      label: 'Project Type',
      required: false,
      value: _selectedProjectType,
      hintText: 'Select project type',
      items: ['Borey', 'Condo', 'Commercial', 'Mixed-use', 'Land Subdivision'],
      onChanged: (val) => setState(() => _selectedProjectType = val),
    );
  }

  Widget _buildBoreyCompletionStatusField() {
    return _buildDropdown(
      label: 'Completion Status',
      required: false,
      value: _selectedCompletionStatus,
      hintText: 'Select status',
      items: [
        'Pre-launch',
        'Under Construction',
        '50% Completed',
        '80% Completed',
        'Completed',
      ],
      onChanged: (val) => setState(() => _selectedCompletionStatus = val),
    );
  }

  Widget _buildLeaseRemainingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PropertySectionTitle(title: 'Lease Remaining', required: false),
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
                controller: _leaseRemainingController,
                decoration: defaultPropertyInputDecoration('Duration'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedLeaseUnit ?? 'Months',
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
                onChanged: (val) => setState(() => _selectedLeaseUnit = val),
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

  Widget _buildDropdown({
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
