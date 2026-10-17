// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/add_property_controller.dart';
import 'add_property_page.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

extension AddPropertyPageLogic on AddPropertyPageState {
  void validateAndSubmit() async {
    setState(() => hasAttemptedSubmit = true);

    final validation = ref
        .read(addPropertyControllerProvider.notifier)
        .validatePropertyForm(
          title: titleController.text,
          price: priceController.text,
          propertyType: selectedPropertyType,
          listingSetting: selectedListingSetting,
          landSize: landSizeController.text,
          buildingSize: buildingSizeController.text,
          unitSize: unitSizeController.text,
        );

    if (!validation.isValid) {
      GlobalKey? firstErrorKey;
      switch (validation.firstErrorField) {
        case PropertyField.title:
          firstErrorKey = titleKey;
          break;
        case PropertyField.price:
          firstErrorKey = priceKey;
          break;
        case PropertyField.listingSettings:
          firstErrorKey = listingSettingsKey;
          break;
        case PropertyField.landSize:
          firstErrorKey = landSizeKey;
          break;
        case PropertyField.buildingSize:
          firstErrorKey = buildingSizeKey;
          break;
        case PropertyField.unitSize:
          firstErrorKey = unitSizeKey;
          break;
        default:
          break;
      }

      if (firstErrorKey != null) {
        showErrorDialog(firstErrorKey);
      }
      return;
    }

    try {
      final property = await ref
          .read(addPropertyControllerProvider.notifier)
          .submitProperty(
            title: titleController.text,
            price: priceController.text,
            propertyType: selectedPropertyType,
            landSize: landSizeController.text,
            buildingSize: buildingSizeController.text,
            unitSize: unitSizeController.text,
            boundaryPoints: widget.boundaryPoints,
            selectedPhotos: selectedPhotos,
            status: 'Active',
          );
      if (!mounted) return;
      if (property != null) {
        showSuccessDialog(property);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void showErrorDialog(GlobalKey firstErrorKey) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            context.l10n.propertyValidateRequiredFields,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            context.l10n.propertyPleaseCompleteRequiredFieldsBeforePublis,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (firstErrorKey.currentContext != null) {
                  Scrollable.ensureVisible(
                    firstErrorKey.currentContext!,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(
                context.l10n.propertyClose,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(PropertyModel property) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            'Property Published\nSuccessfully!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            context.l10n.propertyYourListingIsNowVisibleTo,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(
                  context,
                  property,
                ); // Pop AddPropertyPage with property
              },
              child: Text(
                context.l10n.propertyClose,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PublishButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const PublishButtonWidget({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnimatedSlide(
      offset: isKeyboardOpen ? const Offset(0, 1.2) : Offset.zero,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutQuad,
      child: AnimatedOpacity(
        opacity: isKeyboardOpen ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
        child: IgnorePointer(
          ignoring: isKeyboardOpen,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
              bottom: 70.0,
            ),
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.upload_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
              label: Text(
                isLoading ? 'Publishing your property...' : 'Publish Property',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
