import 'package:flutter/material.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';

class TitleTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const TitleTypeFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Title Type',
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
      label: 'Bedrooms',
      required: false,
      value: value,
      hintText: 'Number of bedrooms',
      items: items,
      onChanged: onChanged,
    );
  }
}

class BathroomsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BathroomsFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Bathrooms',
      required: false,
      value: value,
      hintText: 'Number of bathrooms',
      items: const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class FloorsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const FloorsFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Floors',
      required: false,
      value: value,
      hintText: 'Total floors (e.g. 2)',
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class NumberOfFloorsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const NumberOfFloorsFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Number of Floors',
      required: false,
      value: value,
      hintText: 'Number of Floors',
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class FloorNumberFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const FloorNumberFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Floor Number',
      required: false,
      value: value,
      hintText: 'Enter floor number (e.g. 12)',
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class TotalFloorsFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const TotalFloorsFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Total Floors',
      required: false,
      value: value,
      hintText: 'Total floors in building',
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class ParkingFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ParkingFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Parking',
      required: false,
      value: value,
      hintText: 'Select parking',
      items: const ['Yes', 'No'],
      onChanged: onChanged,
    );
  }
}

class FurnishedFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const FurnishedFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Furnished',
      required: false,
      value: value,
      hintText: 'Select furnished',
      items: const ['Unfurnished', 'Fully Furnished', 'Electrical appliances'],
      onChanged: onChanged,
    );
  }
}

class BuildingTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BuildingTypeFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Building Type',
      required: false,
      value: value,
      hintText: 'Select building type',
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

  const TotalUnitsFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Total Units',
      required: false,
      value: value,
      hintText: 'Number of units',
      items: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: onChanged,
    );
  }
}

class BalconyFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BalconyFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Balcony',
      required: false,
      value: value,
      hintText: 'Select balcony',
      items: const ['Yes', 'No'],
      onChanged: onChanged,
    );
  }
}

class CompletionStatusFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const CompletionStatusFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Completion Status',
      required: false,
      value: value,
      hintText: 'Select Status',
      items: const ['Off-plan', 'Under Construction', 'Completed'],
      onChanged: onChanged,
    );
  }
}

class ViewTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ViewTypeFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'View Type',
      required: false,
      value: value,
      hintText: 'Select view type',
      items: const ['City View', 'River View', 'Garden View', 'Pool View', 'No View'],
      onChanged: onChanged,
    );
  }
}

class ProjectTypeFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ProjectTypeFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Project Type',
      required: false,
      value: value,
      hintText: 'Select project type',
      items: const ['Borey', 'Condo', 'Commercial', 'Mixed-use', 'Land Subdivision'],
      onChanged: onChanged,
    );
  }
}

class BoreyCompletionStatusFieldWidget extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const BoreyCompletionStatusFieldWidget({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PropertyDropdown(
      label: 'Completion Status',
      required: false,
      value: value,
      hintText: 'Select status',
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
