import 'package:flutter/material.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:genie/l10n/l10n.dart';

class TitleTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const TitleTypeFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyTitleType,
      required: false,
      value: value,
      items: const ['Hard Title', 'Soft Title', 'Other'],
      onChanged: onChanged,
    );
  }
}

class BedroomsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isCondo;

  const BedroomsFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.isCondo = false,
  });

  @override
  Widget build(BuildContext context) {
    List<String> items = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'];
    if (isCondo) {
      items.insert(0, 'Studio');
    } else {
      items.insert(0, '0');
    }
    return PropertyDropdown(
      label: context.l10n.propertyBedrooms,
      required: false,
      value: value,
      hintText: context.l10n.propertyNumberOfBedrooms,
      items: items,
      onChanged: onChanged,
    );
  }
}

class BathroomsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BathroomsFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyBathrooms,
      required: false,
      value: value,
      hintText: context.l10n.propertyNumberOfBathrooms,
      items: const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class FloorsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const FloorsFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyFloors,
      required: false,
      value: value,
      hintText: context.l10n.propertyTotalFloorsEG2,
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class NumberOfFloorsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const NumberOfFloorsFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyNumberOfFloors,
      required: false,
      value: value,
      hintText: context.l10n.propertyNumberOfFloors,
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class FloorNumberFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const FloorNumberFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyFloorNumber,
      required: false,
      value: value,
      hintText: context.l10n.propertyEnterFloorNumberEG12,
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class TotalFloorsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const TotalFloorsFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyTotalFloors,
      required: false,
      value: value,
      hintText: context.l10n.propertyTotalFloorsInBuilding,
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class ParkingFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ParkingFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyParking,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectParking,
      items: const ['Yes', 'No'],
      onChanged: onChanged,
    );
  }
}

class FurnishedFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const FurnishedFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyFurnished,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectFurnished,
      items: const ['Unfurnished', 'Fully Furnished', 'Electrical appliances'],
      onChanged: onChanged,
    );
  }
}

class BuildingTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BuildingTypeFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyBuildingType,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectBuildingType,
      items: const [
        'Commercial Building',
        'Office Building',
        'Mixed-use',
        'Retail Building',
        'Warehouse',
      ],
      onChanged: onChanged,
    );
  }
}

class TotalUnitsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const TotalUnitsFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyTotalUnits,
      required: false,
      value: value,
      hintText: context.l10n.propertyNumberOfUnits,
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class BalconyFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BalconyFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyBalcony,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectBalcony,
      items: const ['Yes', 'No'],
      onChanged: onChanged,
    );
  }
}

class CompletionStatusFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const CompletionStatusFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyCompletionStatus,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectStatus,
      items: const ['Off-plan', 'Under Construction', 'Completed'],
      onChanged: onChanged,
    );
  }
}

class ViewTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ViewTypeFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyViewType,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectViewType,
      items: const [
        'City View',
        'River View',
        'Garden View',
        'Pool View',
        'No View',
      ],
      onChanged: onChanged,
    );
  }
}

class ProjectTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ProjectTypeFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyProjectType,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectProjectType,
      items: const [
        'Borey',
        'Condo',
        'Commercial',
        'Mixed-use',
        'Land Subdivision',
      ],
      onChanged: onChanged,
    );
  }
}

class BoreyCompletionStatusFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BoreyCompletionStatusFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: context.l10n.propertyCompletionStatus,
      required: false,
      value: value,
      hintText: context.l10n.propertySelectStatus2,
      items: const [
        'Pre-launch',
        'Under Construction',
        '50% Completed',
        '80% Completed',
        'Completed',
      ],
      onChanged: onChanged,
    );
  }
}
