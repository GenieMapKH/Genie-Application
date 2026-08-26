// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'add_property_page.dart';
import 'add_property_page_layout.dart';

extension AddPropertyPageLogic on AddPropertyPageState {
  void validateForm() {
    setState(() => hasAttemptedSubmit = true);

    GlobalKey? firstErrorKey;

    if (titleController.text.trim().isEmpty) firstErrorKey ??= titleKey;

    if (selectedPropertyType == 'Land' || selectedPropertyType.isEmpty) {
      if (priceController.text.trim().isEmpty) firstErrorKey ??= priceKey;
      if (selectedListingSetting.isEmpty) {
        firstErrorKey ??= listingSettingsKey;
      }
      if (landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= landSizeKey;
      }
    } else if (selectedPropertyType == 'House' ||
        selectedPropertyType == 'Warehouse') {
      if (priceController.text.trim().isEmpty) firstErrorKey ??= priceKey;
      if (selectedListingSetting.isEmpty) {
        firstErrorKey ??= listingSettingsKey;
      }
      if (landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= landSizeKey;
      }
      if (buildingSizeController.text.trim().isEmpty) {
        firstErrorKey ??= buildingSizeKey;
      }
    } else if (selectedPropertyType == 'Building') {
      if (priceController.text.trim().isEmpty) firstErrorKey ??= priceKey;
      if (selectedListingSetting.isEmpty) {
        firstErrorKey ??= listingSettingsKey;
      }
      if (landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= landSizeKey;
      }
      if (buildingSizeController.text.trim().isEmpty) {
        firstErrorKey ??= buildingSizeKey;
      }
    } else if (selectedPropertyType == 'Condo') {
      if (priceController.text.trim().isEmpty) firstErrorKey ??= priceKey;
      if (selectedListingSetting.isEmpty) {
        firstErrorKey ??= listingSettingsKey;
      }
      if (unitSizeController.text.trim().isEmpty) {
        firstErrorKey ??= unitSizeKey;
      }
    } else if (selectedPropertyType == 'Borey') {
      // Title is already checked
    } else if (selectedPropertyType == 'Business for Sale') {
      if (landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= landSizeKey;
      }
      if (selectedListingSetting.isEmpty) {
        firstErrorKey ??= listingSettingsKey;
      }
    }

    if (firstErrorKey != null) {
      showErrorDialog(firstErrorKey);
    } else {
      submitForm();
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
            'Validate required fields',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Please complete required fields before publishing.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
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
                'Close',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B5FEF),
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
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Your listing is now visible to buyers.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
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
                'Close',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B5FEF),
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
                backgroundColor: const Color(0xFF5B5FEF),
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
