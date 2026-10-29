// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/shared/widgets/layout/app_header_bar.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_type_selector.dart';
import 'package:tilomnov/features/property/presentation/view_models/add_property_controller.dart';
import 'package:tilomnov/features/property/presentation/widgets/existing_property_photos.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/fields/property_discount_field.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_picker.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_form_inputs.dart';
import 'add_property_page.dart';
import 'add_property_page_forms_dynamic.dart';
import 'add_property_page_logic.dart';
import 'add_property_submit_bar.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

extension AddPropertyPageLayout on AddPropertyPageState {
  Widget buildAddPropertyLayout(BuildContext context) {
    final formState = ref.watch(addPropertyControllerProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: isEditing
                  ? context.l10n.propertyEditProperty
                  : context.l10n.propertyAddProperty,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildMapPreview(),
                      const SizedBox(height: 24),
                      PropertySectionTitle(
                        title: context.l10n.propertyPropertyType,
                        required: false,
                      ),
                      const SizedBox(height: 12),
                      PropertyTypeSelector(
                        selectedPropertyType: selectedPropertyType,
                        onChanged: (val) {
                          setState(() {
                            selectedPropertyType = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      PropertyTextField(
                        label: context.l10n.propertyTitleHeadline,
                        required: true,
                        controller: titleController,
                        hintText: context
                            .l10n
                            .propertyExample10x30LandNearNationalRoad,
                        hasError:
                            hasAttemptedSubmit &&
                            titleController.text.trim().isEmpty,
                        focusKey: titleKey,
                      ),
                      const SizedBox(height: 16),
                      buildDynamicFields(),
                      const SizedBox(height: 16),
                      PropertyDiscountField(
                        controller: discountController,
                        discountType: selectedDiscountType,
                        onTypeChanged: (type) =>
                            setState(() => selectedDiscountType = type),
                        hasError:
                            hasAttemptedSubmit &&
                            !isValidDiscount(
                              discount: discountController.text,
                              discountType: selectedDiscountType,
                              price: effectivePrice,
                            ),
                        focusKey: discountKey,
                      ),
                      const SizedBox(height: 24),
                      PropertySectionTitle(
                        title: context.l10n.propertyDescription,
                        required: false,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: context
                              .l10n
                              .propertyDescribeWhatMakesThisPropertySpecial,
                          hintStyle: GoogleFonts.inter(
                            color: context.colors.textHint,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: context.colors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: context.colors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: context.colors.primaryStrong,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PropertySectionTitle(
                        title: context.l10n.propertyKeywordsFeatures,
                        required: false,
                      ),
                      const SizedBox(height: 12),
                      buildKeywordsWrap(),
                      const SizedBox(height: 24),
                      PropertySectionTitle(
                        title: context.l10n.propertyUploadPropertyPhotos,
                        required: false,
                      ),
                      const SizedBox(height: 12),
                      if (existingPhotoUrls.isNotEmpty ||
                          removedPhotoUrls.isNotEmpty)
                        ExistingPropertyPhotos(
                          urls: existingPhotoUrls,
                          removedCount: removedPhotoUrls.length,
                          onRemove: removeExistingPhoto,
                          onRestore: restoreRemovedPhotos,
                        ),
                      PropertyImagePicker(
                        selectedPhotos: selectedPhotos,
                        onPhotoPicked: pickImage,
                        onPhotoRemoved: (index) {
                          setState(() {
                            selectedPhotos.removeAt(index);
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      PropertyTextField(
                        label: context.l10n.propertyContactInformation,
                        required: false,
                        controller: phoneController,
                        hintText: context.l10n.propertyPhoneNumber0,
                      ),
                      const SizedBox(
                        height: 100,
                      ), // Bottom padding for sticky button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _submitBar(context, formState.isLoading),
    );
  }

  /// Editing saves the changes; a new listing is either published (public)
  /// or archived (kept private, status 'Draft').
  Widget _submitBar(BuildContext context, bool isLoading) {
    final l10n = context.l10n;
    if (isEditing) {
      return AddPropertySubmitBar(
        children: [
          AddPropertySubmitButton(
            label: isLoading
                ? l10n.propertySavingChanges
                : l10n.propertySaveChanges,
            icon: Icons.check_rounded,
            isLoading: isLoading,
            onPressed: isLoading ? null : validateAndSubmit,
          ),
        ],
      );
    }
    return AddPropertySubmitBar(
      children: [
        AddPropertySubmitButton(
          label: l10n.propertyArchive,
          icon: Icons.lock_outline_rounded,
          filled: false,
          isLoading: isLoading && isArchiving,
          onPressed: isLoading ? null : archive,
        ),
        AddPropertySubmitButton(
          label: l10n.propertyPublish,
          icon: Icons.upload_outlined,
          isLoading: isLoading && !isArchiving,
          onPressed: isLoading ? null : validateAndSubmit,
        ),
      ],
    );
  }
}
