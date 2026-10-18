// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/property/presentation/view_models/add_property_controller.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'add_property_page.dart';
import 'add_property_page_form_binding.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

extension AddPropertyPageLogic on AddPropertyPageState {
  /// Publishes a new listing, or saves the edits to an existing one. A
  /// draft being edited may stay incomplete; anything else must be complete.
  void validateAndSubmit() async {
    final editedDraft = isEditing && widget.property!.status == 'Draft';
    if (!editedDraft && !_isComplete()) return;

    if (isEditing) {
      await _saveChanges();
    } else {
      await _publish();
    }
  }

  /// Checks the required fields, pointing at the first one missing.
  bool _isComplete() {
    setState(() => hasAttemptedSubmit = true);

    final validation = ref
        .read(addPropertyControllerProvider.notifier)
        .validatePropertyForm(
          title: titleController.text,
          price: effectivePrice,
          propertyType: selectedPropertyType,
          listingSetting: selectedListingSetting,
          landSize: landSizeController.text,
          buildingSize: buildingSizeController.text,
          unitSize: unitSizeController.text,
          discount: discountController.text,
          discountType: selectedDiscountType,
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
        case PropertyField.discount:
          firstErrorKey = discountKey;
          break;
        default:
          break;
      }

      if (firstErrorKey != null) {
        showErrorDialog(firstErrorKey);
      }
      return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    try {
      final property = await ref
          .read(addPropertyControllerProvider.notifier)
          .updateProperty(
            propertyId: widget.property!.id,
            input: collectFormInput(),
            newPhotos: selectedPhotos,
            removedPhotoUrls: removedPhotoUrls.toList(),
            boundaryPoints: isBoundaryChanged ? widget.boundaryPoints : null,
          );
      if (!mounted) return;
      AppPopup.showSuccess(context, context.l10n.propertyChangesSaved);
      Navigator.of(context).pop(property);
    } catch (e) {
      AppLogger.error('Saving property changes failed', e);
      if (!mounted) return;
      AppPopup.showError(context, context.l10n.propertyCouldNotSaveChanges);
    }
  }

  Future<void> _publish() async {
    try {
      final property = await ref
          .read(addPropertyControllerProvider.notifier)
          .submitProperty(
            input: collectFormInput(),
            boundaryPoints: widget.boundaryPoints,
            selectedPhotos: selectedPhotos,
            status: 'Active',
          );
      if (!mounted) return;
      if (property != null) {
        showSuccessDialog(property);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Could not publish the property', e, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.propertySaveFailed)));
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
            context.l10n.propertyPublishedTitle,
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

  /// "Publish Property" when null.
  final String? label;

  /// "Publishing your property..." when null.
  final String? loadingLabel;

  const PublishButtonWidget({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.label,
    this.loadingLabel,
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
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: context.colors.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.upload_outlined,
                      color: context.colors.onPrimary,
                      size: 20,
                    ),
              label: Text(
                isLoading
                    ? loadingLabel ?? context.l10n.propertyPublishing
                    : label ?? context.l10n.propertyPublishProperty,
                style: GoogleFonts.inter(
                  color: context.colors.onPrimary,
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
