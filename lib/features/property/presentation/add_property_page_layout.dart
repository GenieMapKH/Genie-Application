// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'add_property_page.dart';

extension AddPropertyPageLayout on _AddPropertyPageState {
  Widget _buildAddPropertyLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B5563)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Property',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              () async {
                try {
                  final property = await _savePropertyToApi('Draft');
                  if (context.mounted) Navigator.of(context).pop(property);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving draft: ${e.toString()}'),
                      ),
                    );
                  }
                }
              }();
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: const Color(0xFF3E49C7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMapPreview(),
              const SizedBox(height: 24),
              const PropertySectionTitle(
                title: 'Property Type',
                required: false,
              ),
              const SizedBox(height: 12),
              PropertyTypeSelector(
                selectedPropertyType: _selectedPropertyType,
                onChanged: (val) {
                  setState(() {
                    _selectedPropertyType = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              PropertyTextField(
                label: 'Title/Headline',
                required: true,
                controller: _titleController,
                hintText: 'Example: 10x30 Land Near National Road 1',
                hasError:
                    _hasAttemptedSubmit && _titleController.text.trim().isEmpty,
                focusKey: _titleKey,
              ),
              const SizedBox(height: 16),
              _buildDynamicFields(),
              const SizedBox(height: 24),
              const PropertySectionTitle(title: 'Description', required: false),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what makes this property special',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFF3E49C7)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const PropertySectionTitle(
                title: 'Keywords / Features',
                required: false,
              ),
              const SizedBox(height: 12),
              _buildKeywordsWrap(),
              const SizedBox(height: 24),
              const PropertySectionTitle(
                title: 'Upload property photos',
                required: false,
              ),
              const SizedBox(height: 12),
              PropertyImagePicker(
                selectedPhotos: _selectedPhotos,
                onPhotoPicked: _pickImage,
                onPhotoRemoved: (index) {
                  setState(() {
                    _selectedPhotos.removeAt(index);
                  });
                },
              ),
              const SizedBox(height: 24),
              PropertyTextField(
                label: 'Contact Information',
                required: false,
                controller: _phoneController,
                hintText: 'Phone Number (0...)',
              ),
              const SizedBox(height: 100), // Bottom padding for sticky button
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _PublishButtonWidget(
        isLoading: _isLoading,
        onPressed: _validateForm,
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);
    try {
      final property = await _savePropertyToApi('Active');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog(property);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<PropertyModel> _savePropertyToApi(String status) async {
    final repo = ref.read(propertyRepositoryProvider);
    final data = {
      'title': _titleController.text.trim().isEmpty
          ? 'Untitled Property'
          : _titleController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'propertyType': _selectedPropertyType.isEmpty
          ? 'Land'
          : _selectedPropertyType,
      if (_landSizeController.text.trim().isNotEmpty)
        'landSize': double.tryParse(_landSizeController.text.trim()),
      if (_buildingSizeController.text.trim().isNotEmpty)
        'buildingSize': double.tryParse(_buildingSizeController.text.trim()),
      if (_unitSizeController.text.trim().isNotEmpty)
        'unitSize': double.tryParse(_unitSizeController.text.trim()),
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
    if (_selectedPhotos.isNotEmpty) {
      property = await repo.uploadImages(property.id, _selectedPhotos);
    }

    return property;
  }
}
