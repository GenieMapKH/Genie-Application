// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/app_header_bar.dart';
import 'package:genie/features/property/presentation/view_models/add_property_controller.dart';
import 'package:genie/features/property/presentation/widgets/property_type_selector.dart';
import 'package:genie/features/property/presentation/widgets/property_image_picker.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'add_property_page.dart';
import 'add_property_page_forms_dynamic.dart';
import 'add_property_page_logic.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

extension AddPropertyPageLayout on AddPropertyPageState {
  Widget buildAddPropertyLayout(BuildContext context) {
    final formState = ref.watch(addPropertyControllerProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: context.l10n.propertyAddProperty,
              trailing: TextButton(
                onPressed: () {
                  () async {
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
                            status: 'Draft',
                          );
                      if (context.mounted && property != null) {
                        Navigator.of(context).pop(property);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error saving draft: ${e.toString()}',
                            ),
                          ),
                        );
                      }
                    }
                  }();
                },
                child: Text(
                  context.l10n.commonSave,
                  style: GoogleFonts.inter(
                    color: context.colors.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
      floatingActionButton: PublishButtonWidget(
        isLoading: formState.isLoading,
        onPressed: validateAndSubmit,
      ),
    );
  }
}
