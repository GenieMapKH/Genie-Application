import 'package:flutter/material.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import '../fields/property_size_fields.dart';
import '../fields/property_dropdown_fields.dart';
import '../fields/property_misc_fields.dart';

/// A warehouse: the plot and the floor area under roof, with the floors,
/// parking and title. No bedrooms, bathrooms or furnishing, as a home has.
class WarehousePropertyForm extends StatelessWidget {
  final AddPropertyPageState state;
  final Function(VoidCallback) updateState;

  const WarehousePropertyForm({
    super.key,
    required this.state,
    required this.updateState,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = SizedBox(height: 16);
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
        spacing,
        LandSizeFieldWidget(state: state),
        spacing,
        BuildingSizeFieldWidget(state: state),
        spacing,
        FloorsFieldWidget(
          value: state.selectedFloors,
          onChanged: (val) => updateState(() => state.selectedFloors = val),
        ),
        spacing,
        ParkingFieldWidget(
          value: state.selectedParking,
          onChanged: (val) => updateState(() => state.selectedParking = val),
        ),
        spacing,
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
