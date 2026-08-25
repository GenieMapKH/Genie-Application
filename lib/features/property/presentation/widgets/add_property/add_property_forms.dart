import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/add_property_page.dart';
import '../property_type_selector.dart';
import '../property_image_picker.dart';
import '../property_form_inputs.dart';
import 'package:genie/features/home/utils/map_measurements.dart';


class AddPropertyLayoutWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const AddPropertyLayoutWidget({super.key, required this.state, BuildContext context});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B5563)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Property',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              () async {
                try {
                  final property = await state._savePropertyToApi('Draft');
                  if (context.state.mounted) Navigator.of(context).pop(property);
                }
}

class LandSizeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const LandSizeFieldWidget({super.key, required this.state, {bool isLandType = false}});

  @override
  Widget build(BuildContext context) {
    
    return Column(
      key: state.landSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: isLandType ? 'Size' : 'Land Size',
              required: true,
              hasError:
                  state.hasAttemptedSubmit &&
                  state.landSizeController.text.trim().isEmpty,
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
          controller: state.landSizeController,
          decoration: defaultPropertyInputDecoration(
            isLandType ? 'Size Area' : 'Enter land size',
            hasError:
                state.hasAttemptedSubmit && state.landSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }
}

class TitleTypeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const TitleTypeFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Title Type',
      required: false,
      value: state.selectedTitleType,
      items: ['Hard Title', 'Soft Title', 'Other'],
      onChanged: (val) {
        if (val != null) state.updateState(() => state.selectedTitleType = val);
      }
}

class BuildingSizeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const BuildingSizeFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return Column(
      key: state.buildingSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: 'Building Size',
              required: true,
              hasError:
                  state.hasAttemptedSubmit &&
                  state.buildingSizeController.text.trim().isEmpty,
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
          controller: state.buildingSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter building size',
            hasError:
                state.hasAttemptedSubmit &&
                state.buildingSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }
}

class UnitSizeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const UnitSizeFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return Column(
      key: state.unitSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PropertySectionTitle(
              title: 'Unit Size',
              required: true,
              hasError:
                  state.hasAttemptedSubmit &&
                  state.unitSizeController.text.trim().isEmpty,
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
          controller: state.unitSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter unit size',
            hasError:
                state.hasAttemptedSubmit && state.unitSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }
}

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

class BedroomsFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const BedroomsFieldWidget({super.key, required this.state, {bool isCondo = false}});

  @override
  Widget build(BuildContext context) {
    
    List<String> items = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'];
    if (isCondo) {
      items.insert(0, 'Studio');
    }
}

class BathroomsFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const BathroomsFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Bathrooms',
      required: false,
      value: state.selectedBathrooms,
      hintText: 'Number of bathrooms',
      items: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => state.updateState(() => state.selectedBathrooms = val),
    );
  }
}

class FloorsFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const FloorsFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Floors',
      required: false,
      value: state.selectedFloors,
      hintText: 'Total floors (e.g. 2)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => state.updateState(() => state.selectedFloors = val),
    );
  }
}

class NumberofFloorsFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const NumberofFloorsFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Number of Floors',
      required: false,
      value: state.selectedFloors,
      hintText: 'Number of Floors',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => state.updateState(() => state.selectedFloors = val),
    );
  }
}

class FloorNumberFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const FloorNumberFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Floor Number',
      required: false,
      value: state.selectedFloorNumber,
      hintText: 'Enter floor number (e.g. 12)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => state.updateState(() => state.selectedFloorNumber = val),
    );
  }
}

class TotalFloorsFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const TotalFloorsFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Total Floors',
      required: false,
      value: state.selectedFloors,
      hintText: 'Total floors in building',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => state.updateState(() => state.selectedFloors = val),
    );
  }
}

class ParkingFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const ParkingFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Parking',
      required: false,
      value: state.selectedParking,
      hintText: 'Select parking',
      items: ['Yes', 'No'],
      onChanged: (val) => state.updateState(() => state.selectedParking = val),
    );
  }
}

class FurnishedFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const FurnishedFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Furnished',
      required: false,
      value: state.selectedFurnished,
      hintText: 'Select furnished',
      items: ['Unfurnished', 'Fully Furnished', 'Electrical appliances'],
      onChanged: (val) => state.updateState(() => state.selectedFurnished = val),
    );
  }
}

class BuildingTypeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const BuildingTypeFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Building Type',
      required: false,
      value: state.selectedBuildingType,
      hintText: 'Select building type',
      items: [
        'Commercial Building',
        'Office Building',
        'Mixed-use',
        'Retail Building',
        'Warehouse',
      ],
      onChanged: (val) => state.updateState(() => state.selectedBuildingType = val),
    );
  }
}

class TotalUnitsFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const TotalUnitsFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Total Units',
      required: false,
      value: state.selectedTotalUnits,
      hintText: 'Number of units',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => state.updateState(() => state.selectedTotalUnits = val),
    );
  }
}

class BalconyFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const BalconyFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Balcony',
      required: false,
      value: state.selectedBalcony,
      hintText: 'Select balcony',
      items: ['Yes', 'No'],
      onChanged: (val) => state.updateState(() => state.selectedBalcony = val),
    );
  }
}

class CompletionStatusFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const CompletionStatusFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Completion Status',
      required: false,
      value: state.selectedCompletionStatus,
      hintText: 'Select Status',
      items: ['Off-plan', 'Under Construction', 'Completed'],
      onChanged: (val) => state.updateState(() => state.selectedCompletionStatus = val),
    );
  }
}

class ViewTypeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const ViewTypeFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'View Type',
      required: false,
      value: state.selectedViewType,
      hintText: 'Select view type',
      items: ['City View', 'River View', 'Garden View', 'Pool View', 'No View'],
      onChanged: (val) => state.updateState(() => state.selectedViewType = val),
    );
  }
}

class ProjectTypeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const ProjectTypeFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Project Type',
      required: false,
      value: state.selectedProjectType,
      hintText: 'Select project type',
      items: ['Borey', 'Condo', 'Commercial', 'Mixed-use', 'Land Subdivision'],
      onChanged: (val) => state.updateState(() => state.selectedProjectType = val),
    );
  }
}

class BoreyCompletionStatusFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const BoreyCompletionStatusFieldWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return state._buildDropdown(
      label: 'Completion Status',
      required: false,
      value: state.selectedCompletionStatus,
      hintText: 'Select status',
      items: [
        'Pre-launch',
        'Under Construction',
        '50% Completed',
        '80% Completed',
        'Completed',
      ],
      onChanged: (val) => state.updateState(() => state.selectedCompletionStatus = val),
    );
  }
}

class LeaseRemainingFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const LeaseRemainingFieldWidget({super.key, required this.state});

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
                onChanged: (val) => state.updateState(() => state.selectedLeaseUnit = val),
                items: ['Months', 'Years'].map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }
}

class MapPreviewWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const MapPreviewWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PropertySectionTitle(title: 'Map Preview', required: false),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: state.widget.boundaryPoints.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: state.widget.boundaryPoints.first,
                      zoom: 16,
                    ),
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    polygons: {
                      Polygon(
                        polygonId: const PolygonId('preview'),
                        points: state.widget.boundaryPoints,
                        fillColor: const Color(
                          0xFF5B5FEF,
                        ).withValues(alpha: 0.2),
                        strokeColor: const Color(0xFF5B5FEF),
                        strokeWidth: 2,
                      ),
                    }
}

class KeywordsWrapWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const KeywordsWrapWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: state.keywords.map((kw) {
        final isSelected = state.selectedKeywords.contains(kw['name']);
        return GestureDetector(
          onTap: () {
            state.updateState(() {
              if (isSelected) {
                state.selectedKeywords.remove(kw['name']);
              }
}

class BottomBarWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const BottomBarWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
      ),
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            iconPath: 'assets/icons/explore.svg',
            label: 'Explore',
            isSelected: true,
          ),
          _buildNavItem(iconPath: 'assets/icons/saved.svg', label: 'Saved'),
          _buildNavItem(iconPath: 'assets/icons/chat.svg', label: 'Chat'),
          _buildNavItem(
            iconPath: 'assets/icons/property.svg',
            label: 'My Properties',
          ),
          _buildNavItem(iconPath: 'assets/icons/user.svg', label: 'User'),
        ],
      ),
    );
  }
}

class DefaultPriceListingSettingsWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const DefaultPriceListingSettingsWidget({super.key, required this.state});

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
                state.hasAttemptedSubmit && state.priceController.text.trim().isEmpty,
            focusKey: state.priceKey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: state._buildDropdown(
            label: 'Listing Settings',
            required: true,
            value: state.selectedListingSetting,
            items: ['Sale', 'Rent', 'To Let'],
            hasError: state.hasAttemptedSubmit && state.selectedListingSetting.isEmpty,
            focusKey: state.listingSettingsKey,
            onChanged: (val) {
              if (val != null) state.updateState(() => state.selectedListingSetting = val);
            }
}

class DynamicFieldsWidget extends StatelessWidget {
  final AddPropertyPageState state;
  const DynamicFieldsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    
    List<Widget> fields = [];
    void addSpacing() => fields.add(const SizedBox(height: 16));

    if (state.selectedPropertyType == 'Land' || state.selectedPropertyType.isEmpty) {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildLandSizeField(isLandType: true));
      addSpacing();
      fields.add(_buildTitleTypeField());
    }
}
