import 'package:flutter/material.dart';
import 'package:genie/features/property/presentation/screens/add_property_page.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import '../fields/property_size_fields.dart';
import '../fields/property_dropdown_fields.dart';
import '../fields/property_misc_fields.dart';

Widget _buildSpacing() => const SizedBox(height: 16);

class LandPropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const LandPropertyForm({super.key, required this.state, required this.updateState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) updateState(() => state.selectedListingSetting = val);
          },
        ),
        _buildSpacing(),
        LandSizeFieldWidget(state: state, isLandType: true),
        _buildSpacing(),
        TitleTypeFieldWidget(
          value: state.selectedTitleType,
          onChanged: (val) {
            if (val != null) updateState(() => state.selectedTitleType = val);
          },
        ),
      ],
    );
  }
}

class HousePropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const HousePropertyForm({super.key, required this.state, required this.updateState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) updateState(() => state.selectedListingSetting = val);
          },
        ),
        _buildSpacing(),
        LandSizeFieldWidget(state: state),
        _buildSpacing(),
        BuildingSizeFieldWidget(state: state),
        _buildSpacing(),
        BedroomsFieldWidget(
          value: state.selectedBedrooms,
          onChanged: (val) => updateState(() => state.selectedBedrooms = val),
        ),
        _buildSpacing(),
        BathroomsFieldWidget(
          value: state.selectedBathrooms,
          onChanged: (val) => updateState(() => state.selectedBathrooms = val),
        ),
        _buildSpacing(),
        FloorsFieldWidget(
          value: state.selectedFloors,
          onChanged: (val) => updateState(() => state.selectedFloors = val),
        ),
        _buildSpacing(),
        ParkingFieldWidget(
          value: state.selectedParking,
          onChanged: (val) => updateState(() => state.selectedParking = val),
        ),
        _buildSpacing(),
        FurnishedFieldWidget(
          value: state.selectedFurnished,
          onChanged: (val) => updateState(() => state.selectedFurnished = val),
        ),
        _buildSpacing(),
        TitleTypeFieldWidget(
          value: state.selectedTitleType,
          onChanged: (val) {
            if (val != null) updateState(() => state.selectedTitleType = val);
          },
        ),
      ],
    );
  }
}

class BuildingPropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const BuildingPropertyForm({super.key, required this.state, required this.updateState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) updateState(() => state.selectedListingSetting = val);
          },
        ),
        _buildSpacing(),
        BuildingTypeFieldWidget(
          value: state.selectedBuildingType,
          onChanged: (val) => updateState(() => state.selectedBuildingType = val),
        ),
        _buildSpacing(),
        LandSizeFieldWidget(state: state),
        _buildSpacing(),
        BuildingSizeFieldWidget(state: state),
        _buildSpacing(),
        NumberOfFloorsFieldWidget(
          value: state.selectedFloors,
          onChanged: (val) => updateState(() => state.selectedFloors = val),
        ),
        _buildSpacing(),
        TotalUnitsFieldWidget(
          value: state.selectedTotalUnits,
          onChanged: (val) => updateState(() => state.selectedTotalUnits = val),
        ),
        _buildSpacing(),
        ParkingFieldWidget(
          value: state.selectedParking,
          onChanged: (val) => updateState(() => state.selectedParking = val),
        ),
        _buildSpacing(),
        TitleTypeFieldWidget(
          value: state.selectedTitleType,
          onChanged: (val) {
            if (val != null) updateState(() => state.selectedTitleType = val);
          },
        ),
      ],
    );
  }
}

class CondoPropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const CondoPropertyForm({super.key, required this.state, required this.updateState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) updateState(() => state.selectedListingSetting = val);
          },
        ),
        _buildSpacing(),
        UnitSizeFieldWidget(state: state),
        _buildSpacing(),
        FloorNumberFieldWidget(
          value: state.selectedFloorNumber,
          onChanged: (val) => updateState(() => state.selectedFloorNumber = val),
        ),
        _buildSpacing(),
        TotalFloorsFieldWidget(
          value: state.selectedFloors,
          onChanged: (val) => updateState(() => state.selectedFloors = val),
        ),
        _buildSpacing(),
        BedroomsFieldWidget(
          value: state.selectedBedrooms,
          isCondo: true,
          onChanged: (val) => updateState(() => state.selectedBedrooms = val),
        ),
        _buildSpacing(),
        BathroomsFieldWidget(
          value: state.selectedBathrooms,
          onChanged: (val) => updateState(() => state.selectedBathrooms = val),
        ),
        _buildSpacing(),
        BalconyFieldWidget(
          value: state.selectedBalcony,
          onChanged: (val) => updateState(() => state.selectedBalcony = val),
        ),
        _buildSpacing(),
        FurnishedFieldWidget(
          value: state.selectedFurnished,
          onChanged: (val) => updateState(() => state.selectedFurnished = val),
        ),
        _buildSpacing(),
        CompletionStatusFieldWidget(
          value: state.selectedCompletionStatus,
          onChanged: (val) => updateState(() => state.selectedCompletionStatus = val),
        ),
        _buildSpacing(),
        ViewTypeFieldWidget(
          value: state.selectedViewType,
          onChanged: (val) => updateState(() => state.selectedViewType = val),
        ),
        _buildSpacing(),
        MaintenanceFeeFieldWidget(state: state),
        _buildSpacing(),
        TitleTypeFieldWidget(
          value: state.selectedTitleType,
          onChanged: (val) {
            if (val != null) updateState(() => state.selectedTitleType = val);
          },
        ),
      ],
    );
  }
}

class BoreyPropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const BoreyPropertyForm({super.key, required this.state, required this.updateState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyTextField(
          label: 'Developer Name',
          required: false,
          controller: state.developerNameController,
          hintText: 'Example: ABC Development Co., Ltd',
        ),
        _buildSpacing(),
        PropertyTextField(
          label: 'Project Name',
          required: false,
          controller: state.projectNameController,
          hintText: 'Project name',
          infoText: 'Official name of the development project',
        ),
        _buildSpacing(),
        ProjectTypeFieldWidget(
          value: state.selectedProjectType,
          onChanged: (val) => updateState(() => state.selectedProjectType = val),
        ),
        _buildSpacing(),
        PropertyTextField(
          label: 'Total Project Area',
          required: false,
          controller: state.totalProjectAreaController,
          hintText: 'Enter total land size',
          infoText: 'Total land area of entire project',
        ),
        _buildSpacing(),
        PropertyTextField(
          label: 'Total Units',
          required: false,
          controller: state.totalUnitsTextController,
          hintText: 'Total number of units in project',
        ),
        _buildSpacing(),
        BoreyCompletionStatusFieldWidget(
          value: state.selectedCompletionStatus,
          onChanged: (val) => updateState(() => state.selectedCompletionStatus = val),
        ),
        _buildSpacing(),
        PropertyTextField(
          label: 'Starting Price',
          required: false,
          controller: state.startingPriceController,
          hintText: 'Starting price in USD',
          infoText: 'Lowest available unit price',
        ),
        _buildSpacing(),
        TitleTypeFieldWidget(
          value: state.selectedTitleType,
          onChanged: (val) {
            if (val != null) updateState(() => state.selectedTitleType = val);
          },
        ),
      ],
    );
  }
}

class BusinessPropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const BusinessPropertyForm({super.key, required this.state, required this.updateState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LandSizeFieldWidget(state: state, isLandType: true),
        _buildSpacing(),
        PropertyTextField(
          label: 'Monthly Rent',
          required: false,
          controller: state.monthlyRentController,
          hintText: 'Enter monthly shop rent (USD)',
          infoText: 'Lower rent = higher profit potential',
        ),
        _buildSpacing(),
        PropertyDropdown(
          label: 'Listing Settings',
          required: true,
          value: state.selectedListingSetting,
          items: const ['Sale', 'Rent', 'To Let'],
          hasError: state.hasAttemptedSubmit && state.selectedListingSetting.isEmpty,
          focusKey: state.listingSettingsKey,
          onChanged: (val) {
            if (val != null) updateState(() => state.selectedListingSetting = val);
          },
        ),
        _buildSpacing(),
        LeaseRemainingFieldWidget(
          state: state,
          onUnitChanged: (val) => updateState(() => state.selectedLeaseUnit = val),
        ),
        _buildSpacing(),
        PropertyTextField(
          label: 'Equipment Included',
          required: false,
          controller: state.equipmentIncludedController,
          hintText: 'List furniture, kitchen equipment, machines, POS system, etc.',
          infoText: 'Describe assets included in sale',
        ),
        _buildSpacing(),
        PropertyTextField(
          label: 'Reason for Selling',
          required: false,
          controller: state.reasonForSellingController,
          hintText: 'Example: Owner relocating abroad',
        ),
      ],
    );
  }
}
