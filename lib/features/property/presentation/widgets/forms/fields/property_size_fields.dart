import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'package:genie/features/property/presentation/screens/add_property_page.dart';

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
                  state.hasAttemptedSubmit && state.landSizeController.text.trim().isEmpty,
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
                  state.hasAttemptedSubmit && state.unitSizeController.text.trim().isEmpty,
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
