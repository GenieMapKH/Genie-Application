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

extension AddPropertyPageLayout on AddPropertyPageState {
  Widget buildAddPropertyLayout(BuildContext context) {
    final formState = ref.watch(addPropertyControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: 'Add Property',
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
                  'Save',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5B5FEF),
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
                      const PropertySectionTitle(
                        title: 'Property Type',
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
                        label: 'Title/Headline',
                        required: true,
                        controller: titleController,
                        hintText: 'Example: 10x30 Land Near National Road 1',
                        hasError:
                            hasAttemptedSubmit &&
                            titleController.text.trim().isEmpty,
                        focusKey: titleKey,
                      ),
                      const SizedBox(height: 16),
                      buildDynamicFields(),
                      const SizedBox(height: 24),
                      const PropertySectionTitle(
                        title: 'Description',
                        required: false,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe what makes this property special',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: Color(0xFF3E49C7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const PropertySectionTitle(
                        title: 'Keywords / Features',
                        required: false,
                      ),
                      const SizedBox(height: 12),
                      buildKeywordsWrap(),
                      const SizedBox(height: 24),
                      const PropertySectionTitle(
                        title: 'Upload property photos',
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
                        label: 'Contact Information',
                        required: false,
                        controller: phoneController,
                        hintText: 'Phone Number (0...)',
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
