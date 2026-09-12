// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/app_header_bar.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/property/presentation/widgets/property_type_selector.dart';
import 'package:genie/features/property/presentation/widgets/property_image_picker.dart';
import 'package:genie/features/property/presentation/widgets/property_form_inputs.dart';
import 'add_property_page.dart';
import 'add_property_page_forms_dynamic.dart';
import 'add_property_page_logic.dart';

extension AddPropertyPageLayout on AddPropertyPageState {
  Widget buildAddPropertyLayout(BuildContext context) {
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
                      final property = await savePropertyToApi('Draft');
                      if (context.mounted) Navigator.of(context).pop(property);
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
        isLoading: isLoading,
        onPressed: validateForm,
      ),
    );
  }

  Future<void> submitForm() async {
    setState(() => isLoading = true);
    try {
      final property = await savePropertyToApi('Active');
      if (!mounted) return;
      setState(() => isLoading = false);
      showSuccessDialog(property);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<PropertyModel> savePropertyToApi(String status) async {
    final repo = ref.read(propertyRepositoryProvider);
    final data = {
      'title': titleController.text.trim().isEmpty
          ? 'Untitled Property'
          : titleController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'propertyType': selectedPropertyType.isEmpty
          ? 'Land'
          : selectedPropertyType,
      if (landSizeController.text.trim().isNotEmpty)
        'landSize': double.tryParse(landSizeController.text.trim()),
      if (buildingSizeController.text.trim().isNotEmpty)
        'buildingSize': double.tryParse(buildingSizeController.text.trim()),
      if (unitSizeController.text.trim().isNotEmpty)
        'unitSize': double.tryParse(unitSizeController.text.trim()),
      'status': status,
    };

    // 1. Create property
    var property = await repo.create(data);

    // 2. Attach boundary points if we have them
    if (widget.boundaryPoints.isNotEmpty) {
      final points = widget.boundaryPoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();
      property = await repo.updateBoundary(property.id, points);
    }

    // 3. Upload images if selected
    if (selectedPhotos.isNotEmpty) {
      property = await repo.uploadImages(property.id, selectedPhotos);
    }

    return property;
  }
}
