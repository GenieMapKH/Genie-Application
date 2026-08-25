// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
part of 'add_property_page.dart';

extension AddPropertyPageLogic on _AddPropertyPageState {
  void _validateForm() {
    setState(() => _hasAttemptedSubmit = true);

    GlobalKey? firstErrorKey;

    if (_titleController.text.trim().isEmpty) firstErrorKey ??= _titleKey;

    if (_selectedPropertyType == 'Land' || _selectedPropertyType.isEmpty) {
      if (_priceController.text.trim().isEmpty) firstErrorKey ??= _priceKey;
      if (_selectedListingSetting.isEmpty) {
        firstErrorKey ??= _listingSettingsKey;
      }
      if (_landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= _landSizeKey;
      }
    } else if (_selectedPropertyType == 'House' ||
        _selectedPropertyType == 'Warehouse') {
      if (_priceController.text.trim().isEmpty) firstErrorKey ??= _priceKey;
      if (_selectedListingSetting.isEmpty) {
        firstErrorKey ??= _listingSettingsKey;
      }
      if (_landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= _landSizeKey;
      }
      if (_buildingSizeController.text.trim().isEmpty) {
        firstErrorKey ??= _buildingSizeKey;
      }
    } else if (_selectedPropertyType == 'Building') {
      if (_priceController.text.trim().isEmpty) firstErrorKey ??= _priceKey;
      if (_selectedListingSetting.isEmpty) {
        firstErrorKey ??= _listingSettingsKey;
      }
      if (_landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= _landSizeKey;
      }
      if (_buildingSizeController.text.trim().isEmpty) {
        firstErrorKey ??= _buildingSizeKey;
      }
    } else if (_selectedPropertyType == 'Condo') {
      if (_priceController.text.trim().isEmpty) firstErrorKey ??= _priceKey;
      if (_selectedListingSetting.isEmpty) {
        firstErrorKey ??= _listingSettingsKey;
      }
      if (_unitSizeController.text.trim().isEmpty) {
        firstErrorKey ??= _unitSizeKey;
      }
    } else if (_selectedPropertyType == 'Borey') {
      // Title is already checked
    } else if (_selectedPropertyType == 'Business for Sale') {
      if (_landSizeController.text.trim().isEmpty) {
        firstErrorKey ??= _landSizeKey;
      }
      if (_selectedListingSetting.isEmpty) {
        firstErrorKey ??= _listingSettingsKey;
      }
    }

    if (firstErrorKey != null) {
      _showErrorDialog(firstErrorKey);
    } else {
      _submitForm();
    }
  }

  void _showErrorDialog(GlobalKey firstErrorKey) {
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

  void _showSuccessDialog(PropertyModel property) {
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

class _PublishButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PublishButtonWidget({
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
