import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:genie/features/property/presentation/screens/add_property_page.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class LandSizeFieldWidget extends StatelessWidget {
  final AddPropertyPageState state;
  final bool isLandType;

  const LandSizeFieldWidget({
    super.key,
    required this.state,
    this.isLandType = false,
  });

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
                      context.l10n.propertyAutoFromMap,
                      style: GoogleFonts.inter(
                        color: context.colors.textMuted,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: context.colors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.propertyTotalLandAreaOfTheProperty,
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
          controller: state.landSizeController,
          decoration: defaultPropertyInputDecoration(
            context,
            isLandType ? 'Size Area' : 'Enter land size',
            hasError:
                state.hasAttemptedSubmit &&
                state.landSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
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
              title: context.l10n.propertyBuildingSize,
              required: true,
              hasError:
                  state.hasAttemptedSubmit &&
                  state.buildingSizeController.text.trim().isEmpty,
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
                  context.l10n.propertyTotalBuiltUpArea,
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
          controller: state.buildingSizeController,
          decoration: defaultPropertyInputDecoration(
            context,
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
              title: context.l10n.propertyUnitSize,
              required: true,
              hasError:
                  state.hasAttemptedSubmit &&
                  state.unitSizeController.text.trim().isEmpty,
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
                  context.l10n.propertyTotalUsableAreaOfTheUnit,
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
          controller: state.unitSizeController,
          decoration: defaultPropertyInputDecoration(
            context,
            'Enter unit size',
            hasError:
                state.hasAttemptedSubmit &&
                state.unitSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }
}
