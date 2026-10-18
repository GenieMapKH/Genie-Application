import 'package:flutter/material.dart';
import 'package:genie/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import '../fields/property_size_fields.dart';
import '../fields/property_dropdown_fields.dart';
import '../fields/property_misc_fields.dart';
import 'package:genie/l10n/l10n.dart';

Widget _buildSpacing() => const SizedBox(height: 16);

class LandPropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const LandPropertyForm({
    super.key,
    required this.state,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) {
              updateState(() => state.selectedListingSetting = val);
            }
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

  const HousePropertyForm({
    super.key,
    required this.state,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) {
              updateState(() => state.selectedListingSetting = val);
            }
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

  const BuildingPropertyForm({
    super.key,
    required this.state,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) {
              updateState(() => state.selectedListingSetting = val);
            }
          },
        ),
        _buildSpacing(),
        BuildingTypeFieldWidget(
          value: state.selectedBuildingType,
          onChanged: (val) =>
              updateState(() => state.selectedBuildingType = val),
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

  const CondoPropertyForm({
    super.key,
    required this.state,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) {
              updateState(() => state.selectedListingSetting = val);
            }
          },
        ),
        _buildSpacing(),
        UnitSizeFieldWidget(state: state),
        _buildSpacing(),
        FloorNumberFieldWidget(
          value: state.selectedFloorNumber,
          onChanged: (val) =>
              updateState(() => state.selectedFloorNumber = val),
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
          onChanged: (val) =>
              updateState(() => state.selectedCompletionStatus = val),
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

  const BoreyPropertyForm({
    super.key,
    required this.state,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyTextField(
          label: context.l10n.propertyDeveloperName,
          required: false,
          controller: state.developerNameController,
          hintText: context.l10n.propertyExampleAbcDevelopmentCoLtd,
        ),
        _buildSpacing(),
        PropertyTextField(
          label: context.l10n.propertyProjectName,
          required: false,
          controller: state.projectNameController,
          hintText: context.l10n.propertyProjectName2,
          infoText: context.l10n.propertyProjectNameInfo,
        ),
        _buildSpacing(),
        ProjectTypeFieldWidget(
          value: state.selectedProjectType,
          onChanged: (val) =>
              updateState(() => state.selectedProjectType = val),
        ),
        _buildSpacing(),
        PropertyTextField(
          label: context.l10n.propertyTotalProjectArea,
          required: false,
          controller: state.totalProjectAreaController,
          hintText: context.l10n.propertyEnterTotalLandSize,
          infoText: context.l10n.propertyProjectAreaInfo,
        ),
        _buildSpacing(),
        PropertyTextField(
          label: context.l10n.propertyTotalUnits,
          required: false,
          controller: state.totalUnitsTextController,
          hintText: context.l10n.propertyTotalNumberOfUnitsInProject,
        ),
        _buildSpacing(),
        BoreyCompletionStatusFieldWidget(
          value: state.selectedCompletionStatus,
          onChanged: (val) =>
              updateState(() => state.selectedCompletionStatus = val),
        ),
        _buildSpacing(),
        PropertyTextField(
          label: context.l10n.propertyStartingPrice,
          required: false,
          controller: state.startingPriceController,
          hintText: context.l10n.propertyStartingPriceInUsd,
          infoText: context.l10n.propertyStartingPriceInfo,
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

  const BusinessPropertyForm({
    super.key,
    required this.state,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultPriceListingSettingsWidget(
          state: state,
          onListingSettingChanged: (val) {
            if (val != null) {
              updateState(() => state.selectedListingSetting = val);
            }
          },
        ),
        _buildSpacing(),
        LandSizeFieldWidget(state: state, isLandType: true),
        _buildSpacing(),
        PropertyTextField(
          label: context.l10n.propertyMonthlyRent,
          required: false,
          controller: state.monthlyRentController,
          hintText: context.l10n.propertyEnterMonthlyShopRentUsd,
          infoText: context.l10n.propertyMonthlyRentInfo,
        ),
        _buildSpacing(),
        LeaseRemainingFieldWidget(
          state: state,
          onUnitChanged: (val) =>
              updateState(() => state.selectedLeaseUnit = val),
        ),
        _buildSpacing(),
        PropertyTextField(
          label: context.l10n.propertyEquipmentIncluded,
          required: false,
          controller: state.equipmentIncludedController,
          hintText:
              context.l10n.propertyListFurnitureKitchenEquipmentMachinesPos,
          infoText: context.l10n.propertyEquipmentInfo,
        ),
        _buildSpacing(),
        PropertyTextField(
          label: context.l10n.propertyReasonForSelling,
          required: false,
          controller: state.reasonForSellingController,
          hintText: context.l10n.propertyExampleOwnerRelocatingAbroad,
        ),
      ],
    );
  }
}
