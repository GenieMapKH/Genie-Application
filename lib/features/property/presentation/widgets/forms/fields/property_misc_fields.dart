import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/property/presentation/property_labels.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/fields/property_select_field.dart';

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
            PropertySectionTitle(
              title: context.l10n.propertyMaintenanceFee,
              required: false,
            ),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.propertyBuildingManagementFeePerMonth,
                  style: GoogleFonts.inter(
                    color: context.colors.textMuted,
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
            context,
            context.l10n.propertyMaintenanceFeeHint,
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
            PropertySectionTitle(
              title: context.l10n.propertyLeaseRemaining,
              required: false,
            ),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.propertyRemainingContractDurationWithLandlord,
                  style: GoogleFonts.inter(
                    color: context.colors.textMuted,
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
                decoration: defaultPropertyInputDecoration(
                  context,
                  context.l10n.propertyDuration,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: PropertySelectField(
                value: state.selectedLeaseUnit ?? 'Months',
                items: const ['Months', 'Years'],
                labelOf: (item) => propertyValueLabel(context.l10n, item),
                decoration: defaultPropertyInputDecoration(
                  context,
                  context.l10n.propertySelectUnit,
                ),
                onChanged: onUnitChanged,
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
            label: context.l10n.propertyPrice,
            required: true,
            controller: state.priceController,
            hintText: context.l10n.propertyEnterSellingPriceUsd,
            hasError:
                state.hasAttemptedSubmit &&
                state.priceController.text.trim().isEmpty,
            focusKey: state.priceKey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PropertyDropdown(
            label: context.l10n.propertyListingSettings,
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
