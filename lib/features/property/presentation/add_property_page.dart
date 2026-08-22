import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../models/property_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/property_providers.dart';
import 'package:genie/features/property/presentation/widgets/property_type_selector.dart';
import 'package:genie/features/home/utils/map_measurements.dart';
import 'widgets/property_image_picker.dart';
import 'widgets/property_form_inputs.dart';

class AddPropertyPage extends ConsumerStatefulWidget {
  final List<LatLng> boundaryPoints;
  final double propertyArea;

  const AddPropertyPage({
    super.key,
    required this.boundaryPoints,
    required this.propertyArea,
  });

  @override
  ConsumerState<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends ConsumerState<AddPropertyPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _landSizeController = TextEditingController();
  final TextEditingController _buildingSizeController = TextEditingController();
  final TextEditingController _unitSizeController = TextEditingController();
  final TextEditingController _maintenanceFeeController =
      TextEditingController();

  // Borey specific controllers
  final TextEditingController _developerNameController =
      TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _totalProjectAreaController =
      TextEditingController();
  final TextEditingController _totalUnitsTextController =
      TextEditingController();
  final TextEditingController _startingPriceController =
      TextEditingController();

  // Business for Sale specific controllers
  final TextEditingController _monthlyRentController = TextEditingController();
  final TextEditingController _leaseRemainingController =
      TextEditingController();
  final TextEditingController _equipmentIncludedController =
      TextEditingController();
  final TextEditingController _reasonForSellingController =
      TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedPropertyType = 'Land';
  String _selectedListingSetting = 'Sale';
  String _selectedTitleType = 'Hard Title';

  String? _selectedBedrooms;
  String? _selectedBathrooms;
  String? _selectedFloors;
  String? _selectedFloorNumber;
  String? _selectedParking;
  String? _selectedFurnished;
  String? _selectedBuildingType;
  String? _selectedTotalUnits;
  String? _selectedBalcony;
  String? _selectedCompletionStatus;
  String? _selectedViewType;

  // New selected states for Borey & Business
  String? _selectedProjectType;
  String? _selectedLeaseUnit;
  final Set<String> _selectedKeywords = {};

  bool _hasAttemptedSubmit = false;
  bool _isLoading = false;

  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _priceKey = GlobalKey();
  final GlobalKey _listingSettingsKey = GlobalKey();
  final GlobalKey _landSizeKey = GlobalKey();
  final GlobalKey _buildingSizeKey = GlobalKey();
  final GlobalKey _unitSizeKey = GlobalKey();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedPhotos = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 70,
          maxWidth: 1280,
          maxHeight: 1280,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedPhotos.addAll(images);
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1280,
          maxHeight: 1280,
        );
        if (image != null) {
          setState(() {
            _selectedPhotos.add(image);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  final List<Map<String, dynamic>> _keywords = [
    {'name': 'Road Access', 'iconPath': 'assets/icons/keyword_road_access.svg'},
    {'name': 'Corner Land', 'iconPath': 'assets/icons/keyword_corner_land.svg'},
    {'name': 'Near Market', 'iconPath': 'assets/icons/keyword_near_market.svg'},
    {'name': 'Near School', 'iconPath': 'assets/icons/keyword_near_school.svg'},
    {
      'name': 'Near Hospital',
      'iconPath': 'assets/icons/keyword_near_hospital.svg',
    },
    {
      'name': 'River / Lake Nearby',
      'iconPath': 'assets/icons/keyword_river_lake.svg',
    },
    {
      'name': 'Electricity Ready',
      'iconPath': 'assets/icons/keyword_electricity_ready.svg',
    },
    {
      'name': 'Water Supply',
      'iconPath': 'assets/icons/keyword_water_supply.svg',
    },
    {
      'name': 'Residential Area',
      'iconPath': 'assets/icons/keyword_residential_area.svg',
    },
    {
      'name': 'Commercial Area',
      'iconPath': 'assets/icons/keyword_commercial_area.svg',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.propertyArea > 0) {
      _landSizeController.text = formatArea(widget.propertyArea);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _landSizeController.dispose();
    _buildingSizeController.dispose();
    _unitSizeController.dispose();
    _maintenanceFeeController.dispose();
    _developerNameController.dispose();
    _projectNameController.dispose();
    _totalProjectAreaController.dispose();
    _totalUnitsTextController.dispose();
    _startingPriceController.dispose();
    _monthlyRentController.dispose();
    _leaseRemainingController.dispose();
    _equipmentIncludedController.dispose();
    _reasonForSellingController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _buildSectionTitle('Property Type', required: false),
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
              _buildTextField(
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
              _buildSectionTitle('Description', required: false),
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
              _buildSectionTitle('Keywords / Features', required: false),
              const SizedBox(height: 12),
              _buildKeywordsWrap(),
              const SizedBox(height: 24),
              _buildSectionTitle('Upload property photos', required: false),
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
              _buildTextField(
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

  Widget _buildMapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Map Preview', required: false),
        const SizedBox(height: 8),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: widget.boundaryPoints.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.boundaryPoints.first,
                      zoom: 16,
                    ),
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: false,
                    scrollGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    myLocationButtonEnabled: false,
                    polygons: {
                      Polygon(
                        polygonId: const PolygonId('preview'),
                        points: widget.boundaryPoints,
                        fillColor: const Color(
                          0xFF5B5FEF,
                        ).withValues(alpha: 0.2),
                        strokeColor: const Color(0xFF5B5FEF),
                        strokeWidth: 2,
                      ),
                    },
                    onMapCreated: (controller) {
                      final bounds = _boundsFromLatLngList(
                        widget.boundaryPoints,
                      );
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngBounds(bounds, 30),
                          );
                        }
                      });
                    },
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 48, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text(
                      'Set Property Location',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Location & Boundary',
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF374151),
                ),
                label: Text(
                  'Locate Property',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF374151),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: SvgPicture.asset(
                  'assets/icons/draw_property.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                label: Text(
                  'Drawing Property',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeywordsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: _keywords.map((kw) {
        final isSelected = _selectedKeywords.contains(kw['name']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedKeywords.remove(kw['name']);
              } else {
                _selectedKeywords.add(kw['name']);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF5B5FEF).withValues(alpha: 0.05)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5B5FEF)
                    : const Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  kw['iconPath'],
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? const Color(0xFF5B5FEF)
                        : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  kw['name'],
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? const Color(0xFF5B5FEF)
                        : const Color(0xFF4B5563),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
      ),
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            iconPath: 'assets/icons/explore.svg',
            label: 'Explore',
            isSelected: true,
          ),
          _buildNavItem(iconPath: 'assets/icons/saved.svg', label: 'Saved'),
          _buildNavItem(iconPath: 'assets/icons/chat.svg', label: 'Chat'),
          _buildNavItem(
            iconPath: 'assets/icons/property.svg',
            label: 'My Properties',
          ),
          _buildNavItem(iconPath: 'assets/icons/user.svg', label: 'User'),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    bool isSelected = false,
  }) {
    final color = isSelected
        ? const Color(0xFF5B5FEF)
        : const Color(0xFF6B7280);
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    required bool required,
    bool hasError = false,
  }) {
    return PropertySectionTitle(
      title: title,
      required: required,
      hasError: hasError,
    );
  }

  Widget _buildTextField({
    required String label,
    required bool required,
    required TextEditingController controller,
    required String hintText,
    String? infoText,
    bool hasError = false,
    Key? focusKey,
  }) {
    return PropertyTextField(
      label: label,
      required: required,
      controller: controller,
      hintText: hintText,
      infoText: infoText,
      hasError: hasError,
      focusKey: focusKey,
    );
  }

  Widget _buildDefaultPriceListingSettings() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTextField(
            label: 'Price',
            required: true,
            controller: _priceController,
            hintText: 'Enter selling price (USD)',
            hasError:
                _hasAttemptedSubmit && _priceController.text.trim().isEmpty,
            focusKey: _priceKey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(
            label: 'Listing Settings',
            required: true,
            value: _selectedListingSetting,
            items: ['Sale', 'Rent', 'To Let'],
            hasError: _hasAttemptedSubmit && _selectedListingSetting.isEmpty,
            focusKey: _listingSettingsKey,
            onChanged: (val) {
              if (val != null) setState(() => _selectedListingSetting = val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicFields() {
    List<Widget> fields = [];
    void addSpacing() => fields.add(const SizedBox(height: 16));

    if (_selectedPropertyType == 'Land' || _selectedPropertyType.isEmpty) {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildLandSizeField(isLandType: true));
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'House' ||
        _selectedPropertyType == 'Warehouse') {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildLandSizeField());
      addSpacing();
      fields.add(_buildBuildingSizeField());
      addSpacing();
      fields.add(_buildBedroomsField());
      addSpacing();
      fields.add(_buildBathroomsField());
      addSpacing();
      fields.add(_buildFloorsField());
      addSpacing();
      fields.add(_buildParkingField());
      addSpacing();
      fields.add(_buildFurnishedField());
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Building') {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildBuildingTypeField());
      addSpacing();
      fields.add(_buildLandSizeField());
      addSpacing();
      fields.add(_buildBuildingSizeField());
      addSpacing();
      fields.add(_buildNumberofFloorsField());
      addSpacing();
      fields.add(_buildTotalUnitsField());
      addSpacing();
      fields.add(_buildParkingField());
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Condo') {
      fields.add(_buildDefaultPriceListingSettings());
      addSpacing();
      fields.add(_buildUnitSizeField());
      addSpacing();
      fields.add(_buildFloorNumberField());
      addSpacing();
      fields.add(_buildTotalFloorsField());
      addSpacing();
      fields.add(_buildBedroomsField(isCondo: true));
      addSpacing();
      fields.add(_buildBathroomsField());
      addSpacing();
      fields.add(_buildBalconyField());
      addSpacing();
      fields.add(_buildFurnishedField());
      addSpacing();
      fields.add(_buildCompletionStatusField());
      addSpacing();
      fields.add(_buildViewTypeField());
      addSpacing();
      fields.add(_buildMaintenanceFeeField());
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Borey') {
      fields.add(
        _buildTextField(
          label: 'Developer Name',
          required: false,
          controller: _developerNameController,
          hintText: 'Example: ABC Development Co., Ltd',
        ),
      );
      addSpacing();
      fields.add(
        _buildTextField(
          label: 'Project Name',
          required: false,
          controller: _projectNameController,
          hintText: 'Project name',
          infoText: 'Official name of the development project',
        ),
      );
      addSpacing();
      fields.add(_buildProjectTypeField());
      addSpacing();
      fields.add(
        _buildTextField(
          label: 'Total Project Area',
          required: false,
          controller: _totalProjectAreaController,
          hintText: 'Enter total land size',
          infoText: 'Total land area of entire project',
        ),
      );
      addSpacing();
      fields.add(
        _buildTextField(
          label: 'Total Units',
          required: false,
          controller: _totalUnitsTextController,
          hintText: 'Total number of units in project',
        ),
      );
      addSpacing();
      fields.add(_buildBoreyCompletionStatusField());
      addSpacing();
      fields.add(
        _buildTextField(
          label: 'Starting Price',
          required: false,
          controller: _startingPriceController,
          hintText: 'Starting price in USD',
          infoText: 'Lowest available unit price',
        ),
      );
      addSpacing();
      fields.add(_buildTitleTypeField());
    } else if (_selectedPropertyType == 'Business for Sale') {
      fields.add(_buildLandSizeField(isLandType: true));
      addSpacing();
      fields.add(
        _buildTextField(
          label: 'Monthly Rent',
          required: false,
          controller: _monthlyRentController,
          hintText: 'Enter monthly shop rent (USD)',
          infoText: 'Lower rent = higher profit potential',
        ),
      );
      addSpacing();
      fields.add(
        _buildDropdown(
          label: 'Listing Settings',
          required: true,
          value: _selectedListingSetting,
          items: ['Sale', 'Rent', 'To Let'],
          hasError: _hasAttemptedSubmit && _selectedListingSetting.isEmpty,
          focusKey: _listingSettingsKey,
          onChanged: (val) {
            if (val != null) setState(() => _selectedListingSetting = val);
          },
        ),
      );
      addSpacing();
      fields.add(_buildLeaseRemainingField());
      addSpacing();
      fields.add(
        _buildTextField(
          label: 'Equipment Included',
          required: false,
          controller: _equipmentIncludedController,
          hintText:
              'List furniture, kitchen equipment, machines, POS system, etc.',
          infoText: 'Describe assets included in sale',
        ),
      );
      addSpacing();
      fields.add(
        _buildTextField(
          label: 'Reason for Selling',
          required: false,
          controller: _reasonForSellingController,
          hintText: 'Example: Owner relocating abroad',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields,
    );
  }

  Widget _buildLandSizeField({bool isLandType = false}) {
    return Column(
      key: _landSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              isLandType ? 'Size' : 'Land Size',
              required: true,
              hasError:
                  _hasAttemptedSubmit &&
                  _landSizeController.text.trim().isEmpty,
            ),
            isLandType
                ? InkWell(
                    onTap: () {},
                    child: Text(
                      'Auto from map',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Total land area of the property',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _landSizeController,
          decoration: defaultPropertyInputDecoration(
            isLandType ? 'Size Area' : 'Enter land size',
            hasError:
                _hasAttemptedSubmit && _landSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleTypeField() {
    return _buildDropdown(
      label: 'Title Type',
      required: false,
      value: _selectedTitleType,
      items: ['Hard Title', 'Soft Title', 'Other'],
      onChanged: (val) {
        if (val != null) setState(() => _selectedTitleType = val);
      },
    );
  }

  Widget _buildBuildingSizeField() {
    return Column(
      key: _buildingSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              'Building Size',
              required: true,
              hasError:
                  _hasAttemptedSubmit &&
                  _buildingSizeController.text.trim().isEmpty,
            ),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  'Total built-up area',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _buildingSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter building size',
            hasError:
                _hasAttemptedSubmit &&
                _buildingSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSizeField() {
    return Column(
      key: _unitSizeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              'Unit Size',
              required: true,
              hasError:
                  _hasAttemptedSubmit &&
                  _unitSizeController.text.trim().isEmpty,
            ),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  'Total usable area of the unit',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _unitSizeController,
          decoration: defaultPropertyInputDecoration(
            'Enter unit size',
            hasError:
                _hasAttemptedSubmit && _unitSizeController.text.trim().isEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceFeeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Maintenance Fee', required: false),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  'Building management fee per month',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _maintenanceFeeController,
          decoration: defaultPropertyInputDecoration(
            'Monthly maintenance fee (USD)',
          ),
        ),
      ],
    );
  }

  Widget _buildBedroomsField({bool isCondo = false}) {
    List<String> items = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'];
    if (isCondo) {
      items.insert(0, 'Studio');
    } else {
      items.insert(0, '0');
    }
    return _buildDropdown(
      label: 'Bedrooms',
      required: false,
      value: _selectedBedrooms,
      hintText: 'Number of bedrooms',
      items: items,
      onChanged: (val) => setState(() => _selectedBedrooms = val),
    );
  }

  Widget _buildBathroomsField() {
    return _buildDropdown(
      label: 'Bathrooms',
      required: false,
      value: _selectedBathrooms,
      hintText: 'Number of bathrooms',
      items: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedBathrooms = val),
    );
  }

  Widget _buildFloorsField() {
    return _buildDropdown(
      label: 'Floors',
      required: false,
      value: _selectedFloors,
      hintText: 'Total floors (e.g. 2)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloors = val),
    );
  }

  Widget _buildNumberofFloorsField() {
    return _buildDropdown(
      label: 'Number of Floors',
      required: false,
      value: _selectedFloors,
      hintText: 'Number of Floors',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloors = val),
    );
  }

  Widget _buildFloorNumberField() {
    return _buildDropdown(
      label: 'Floor Number',
      required: false,
      value: _selectedFloorNumber,
      hintText: 'Enter floor number (e.g. 12)',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloorNumber = val),
    );
  }

  Widget _buildTotalFloorsField() {
    return _buildDropdown(
      label: 'Total Floors',
      required: false,
      value: _selectedFloors,
      hintText: 'Total floors in building',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedFloors = val),
    );
  }

  Widget _buildParkingField() {
    return _buildDropdown(
      label: 'Parking',
      required: false,
      value: _selectedParking,
      hintText: 'Select parking',
      items: ['Yes', 'No'],
      onChanged: (val) => setState(() => _selectedParking = val),
    );
  }

  Widget _buildFurnishedField() {
    return _buildDropdown(
      label: 'Furnished',
      required: false,
      value: _selectedFurnished,
      hintText: 'Select furnished',
      items: ['Unfurnished', 'Fully Furnished', 'Electrical appliances'],
      onChanged: (val) => setState(() => _selectedFurnished = val),
    );
  }

  Widget _buildBuildingTypeField() {
    return _buildDropdown(
      label: 'Building Type',
      required: false,
      value: _selectedBuildingType,
      hintText: 'Select building type',
      items: [
        'Commercial Building',
        'Office Building',
        'Mixed-use',
        'Retail Building',
        'Warehouse',
      ],
      onChanged: (val) => setState(() => _selectedBuildingType = val),
    );
  }

  Widget _buildTotalUnitsField() {
    return _buildDropdown(
      label: 'Total Units',
      required: false,
      value: _selectedTotalUnits,
      hintText: 'Number of units',
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10+'],
      onChanged: (val) => setState(() => _selectedTotalUnits = val),
    );
  }

  Widget _buildBalconyField() {
    return _buildDropdown(
      label: 'Balcony',
      required: false,
      value: _selectedBalcony,
      hintText: 'Select balcony',
      items: ['Yes', 'No'],
      onChanged: (val) => setState(() => _selectedBalcony = val),
    );
  }

  Widget _buildCompletionStatusField() {
    return _buildDropdown(
      label: 'Completion Status',
      required: false,
      value: _selectedCompletionStatus,
      hintText: 'Select Status',
      items: ['Off-plan', 'Under Construction', 'Completed'],
      onChanged: (val) => setState(() => _selectedCompletionStatus = val),
    );
  }

  Widget _buildViewTypeField() {
    return _buildDropdown(
      label: 'View Type',
      required: false,
      value: _selectedViewType,
      hintText: 'Select view type',
      items: ['City View', 'River View', 'Garden View', 'Pool View', 'No View'],
      onChanged: (val) => setState(() => _selectedViewType = val),
    );
  }

  Widget _buildProjectTypeField() {
    return _buildDropdown(
      label: 'Project Type',
      required: false,
      value: _selectedProjectType,
      hintText: 'Select project type',
      items: ['Borey', 'Condo', 'Commercial', 'Mixed-use', 'Land Subdivision'],
      onChanged: (val) => setState(() => _selectedProjectType = val),
    );
  }

  Widget _buildBoreyCompletionStatusField() {
    return _buildDropdown(
      label: 'Completion Status',
      required: false,
      value: _selectedCompletionStatus,
      hintText: 'Select status',
      items: [
        'Pre-launch',
        'Under Construction',
        '50% Completed',
        '80% Completed',
        'Completed',
      ],
      onChanged: (val) => setState(() => _selectedCompletionStatus = val),
    );
  }

  Widget _buildLeaseRemainingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Lease Remaining', required: false),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  'Remaining contract duration with landlord',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _leaseRemainingController,
                decoration: defaultPropertyInputDecoration('Duration'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedLeaseUnit ?? 'Months',
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF9CA3AF),
                ),
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                decoration: defaultPropertyInputDecoration('Select unit'),
                onChanged: (val) => setState(() => _selectedLeaseUnit = val),
                items: ['Months', 'Years'].map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required bool required,
    required String? value,
    String? hintText,
    required List<String> items,
    required Function(String?) onChanged,
    bool hasError = false,
    Key? focusKey,
  }) {
    return PropertyDropdown(
      label: label,
      required: required,
      value: value,
      hintText: hintText,
      items: items,
      onChanged: onChanged,
      hasError: hasError,
      focusKey: focusKey,
    );
  }

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
