import 'package:tilomnov/shared/utils/phone_number.dart';
import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/property/presentation/view_models/add_property_controller.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'add_property_page.dart';
import 'add_property_page_form_binding.dart';
import 'add_property_paid_publish.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';

extension AddPropertyPageLogic on AddPropertyPageState {
  /// Publishes a new listing, or saves the edits to an existing one. A
  /// draft being edited may stay incomplete; anything else must be complete.
  void validateAndSubmit() async {
    if (isLoading || ref.read(addPropertyControllerProvider).isLoading) return;
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
          price: isTakeover ? '0' : effectivePrice,
          propertyType: selectedPropertyType,
          listingSetting: selectedListingSetting,
          landSize: landSizeController.text,
          buildingSize: buildingSizeController.text,
          unitSize: unitSizeController.text,
          discount: isTakeover ? '' : discountController.text,
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
    if (isTakeover &&
        (takeoverTerms == null || takeoverTerms!.errors.isNotEmpty)) {
      AppPopup.showError(context, context.l10n.takeoverInvalid);
      if (takeoverKey.currentContext != null) {
        Scrollable.ensureVisible(
          takeoverKey.currentContext!,
          duration: const Duration(milliseconds: 300),
        );
      }
      return false;
    }
    final phones = [phoneController, ...additionalPhoneControllers];
    if (phones.any((c) => normalizePhoneNumber(c.text) == null)) {
      AppPopup.showError(context, context.l10n.authErrEnterValidPhone);
      if (contactPhoneKey.currentContext != null) {
        Scrollable.ensureVisible(
          contactPhoneKey.currentContext!,
          duration: const Duration(milliseconds: 300),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    try {
      if (widget.property!.status != 'Draft') {
        await ref
            .read(addPropertyControllerProvider.notifier)
            .ensureAccountPhone(phoneController.text);
      }
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
      showFailure(
        context,
        error: e,
        fallback: context.l10n.propertyCouldNotSaveChanges,
      );
    }
  }

  /// Keeps a new listing private (status 'Draft'): only the owner sees it,
  /// so it may stay incomplete until it is published.
  Future<void> archive() async {
    setState(() => isArchiving = true);
    try {
      final property = await ref
          .read(addPropertyControllerProvider.notifier)
          .submitProperty(
            input: collectFormInput(),
            boundaryPoints: widget.boundaryPoints,
            selectedPhotos: selectedPhotos,
            status: 'Draft',
          );
      if (!mounted || property == null) return;
      AppPopup.showSuccess(context, context.l10n.propertyArchivedPrivately);
      Navigator.of(context).pop(property);
    } catch (e, stackTrace) {
      AppLogger.error('Could not archive the property', e, stackTrace);
      _showSaveFailed(e);
    } finally {
      if (mounted) setState(() => isArchiving = false);
    }
  }

  /// Publishes a new listing: free while it fits in the user's plan, else
  /// the way they chose to pay for it.
  Future<void> _publish() async {
    setState(() => isLoading = true);
    try {
      await ref
          .read(addPropertyControllerProvider.notifier)
          .ensureAccountPhone(phoneController.text);
      final allowance = await ref.read(publishingAllowanceProvider.future);
      if (!mounted) return;
      if (!allowance.hasRoom) {
        await publishBeyondPlan(publishInPlan: _publishInPlan);
      } else {
        await _publishInPlan();
      }
    } catch (error) {
      _showSaveFailed(error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _publishInPlan() async {
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
      _showSaveFailed(e);
    }
  }

  void _showSaveFailed(Object error) {
    if (!mounted) return;
    if (error is DioException &&
        error.response?.data is Map &&
        error.response!.data['code'] == 'PUBLISHING_PLAN_REQUIRED') {
      ref.invalidate(publishingAllowanceProvider);
      setState(() => publishingPlanMissing = true);
    }
    final message = failureMessage(
      context.l10n,
      error: error,
      fallback: context.l10n.propertySaveFailed,
    );
    AppPopup.showError(context, message);
  }

  void showErrorDialog(GlobalKey firstErrorKey) {
    AppDialog.show(
      context,
      builder: (context) {
        return AppDialog.custom(
          icon: Icons.home_outlined,
          tone: AppDialogTone.neutral,

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
    AppDialog.show(
      context,
      builder: (context) {
        return AppDialog.custom(
          icon: Icons.home_outlined,
          tone: AppDialogTone.neutral,

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
