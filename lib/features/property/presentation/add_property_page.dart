import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class AddPropertyPage extends StatefulWidget {
  final List<LatLng> boundaryPoints;
  final double propertyArea;

  const AddPropertyPage({
    super.key,
    required this.boundaryPoints,
    required this.propertyArea,
  });

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedPropertyType = '';
  String _selectedListingSetting = 'Sale';
  String _selectedTitleType = 'Hard Title';
  final Set<String> _selectedKeywords = {};

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedPhotos = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() {
            _selectedPhotos.addAll(images);
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
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

  final List<Map<String, dynamic>> _propertyTypes = [
    {'name': 'Land', 'iconPath': 'assets/icons/property_land.svg'},
    {'name': 'House', 'iconPath': 'assets/icons/property_house.svg'},
    {'name': 'Building', 'iconPath': 'assets/icons/property_building.svg'},
    {'name': 'Condo', 'iconPath': 'assets/icons/property_condo.svg'},
    {'name': 'Borey', 'iconPath': 'assets/icons/property_borey.svg'},
    {'name': 'Business for Sale', 'iconPath': 'assets/icons/property_business.svg'},
    {'name': 'Warehouse', 'iconPath': 'assets/icons/property_warehouse.svg'},
  ];

  final List<Map<String, dynamic>> _keywords = [
    {'name': 'Road Access', 'iconPath': 'assets/icons/keyword_road_access.svg'},
    {'name': 'Corner Land', 'iconPath': 'assets/icons/keyword_corner_land.svg'},
    {'name': 'Near Market', 'iconPath': 'assets/icons/keyword_near_market.svg'},
    {'name': 'Near School', 'iconPath': 'assets/icons/keyword_near_school.svg'},
    {'name': 'Near Hospital', 'iconPath': 'assets/icons/keyword_near_hospital.svg'},
    {'name': 'River / Lake Nearby', 'iconPath': 'assets/icons/keyword_river_lake.svg'},
    {'name': 'Electricity Ready', 'iconPath': 'assets/icons/keyword_electricity_ready.svg'},
    {'name': 'Water Supply', 'iconPath': 'assets/icons/keyword_water_supply.svg'},
    {'name': 'Residential Area', 'iconPath': 'assets/icons/keyword_residential_area.svg'},
    {'name': 'Commercial Area', 'iconPath': 'assets/icons/keyword_commercial_area.svg'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.propertyArea > 0) {
      _sizeController.text = '${widget.propertyArea.toStringAsFixed(0)} m²';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
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
            onPressed: () => Navigator.of(context).pop(true),
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
            _buildPropertyTypeGrid(),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Title/Headline',
              required: true,
              controller: _titleController,
              hintText: 'Example: 10x30 Land Near National Road 1',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Price',
                    required: true,
                    controller: _priceController,
                    hintText: 'Selling price (USD)',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Listing Settings',
                    required: true,
                    value: _selectedListingSetting,
                    items: ['Sale', 'Rent', 'To Let'],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedListingSetting = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSizeField(),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Title Type',
              required: false,
              value: _selectedTitleType,
              items: ['Hard Title', 'Soft Title', 'Other'],
              onChanged: (val) {
                if (val != null) setState(() => _selectedTitleType = val);
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Description', required: false),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe what makes this property special',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
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
            _buildPhotoUploadSection(),
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
      floatingActionButton: const _PublishButtonWidget(),
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
                        fillColor: const Color(0xFF5B5FEF).withValues(alpha: 0.2),
                        strokeColor: const Color(0xFF5B5FEF),
                        strokeWidth: 2,
                      ),
                    },
                    onMapCreated: (controller) {
                      final bounds = _boundsFromLatLngList(widget.boundaryPoints);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 30));
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
          style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF374151)),
                label: Text(
                  'Locate Property',
                  style: GoogleFonts.inter(color: const Color(0xFF374151), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: SvgPicture.asset('assets/icons/draw_property.svg', width: 18, height: 18, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                label: Text(
                  'Drawing Property',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B5FEF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyTypeGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _propertyTypes.map((type) {
        final isSelected = _selectedPropertyType == type['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPropertyType = type['name'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: (MediaQuery.sizeOf(context).width - 32 - 24) / 3, // 3 columns
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF5B5FEF).withValues(alpha: 0.05) : Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFF5B5FEF) : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  type['iconPath'],
                  colorFilter: ColorFilter.mode(
                    isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                  width: 24,
                  height: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  type['name'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF6B7280),
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
              color: isSelected ? const Color(0xFF5B5FEF).withValues(alpha: 0.05) : Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFF5B5FEF) : const Color(0xFFE5E7EB),
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
                    isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  kw['name'],
                  style: GoogleFonts.inter(
                    color: isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF4B5563),
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

  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    _selectedPhotos.length < 4 ? 4 : _selectedPhotos.length + 1,
                    (index) {
                      final boxSize = (MediaQuery.sizeOf(context).width - 32 - 36) / 4;
                      final isPhoto = index < _selectedPhotos.length;
                      return Container(
                        width: boxSize,
                        height: boxSize,
                        margin: EdgeInsets.only(right: index == (_selectedPhotos.length < 4 ? 3 : _selectedPhotos.length) ? 0 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: isPhoto ? null : Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8.0),
                          image: isPhoto 
                              ? DecorationImage(
                                  image: FileImage(File(_selectedPhotos[index].path)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: isPhoto
                            ? Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedPhotos.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Icon(Icons.add, color: Color(0xFF9CA3AF)),
                              ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Add at least 3 clear photos of the property and surrounding area',
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        'Open camera',
                        style: GoogleFonts.inter(color: const Color(0xFF374151), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B5FEF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      child: Text(
                        'Upload property photos',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
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
          _buildNavItem(iconPath: 'assets/icons/explore.svg', label: 'Explore', isSelected: true),
          _buildNavItem(iconPath: 'assets/icons/saved.svg', label: 'Saved'),
          _buildNavItem(iconPath: 'assets/icons/chat.svg', label: 'Chat'),
          _buildNavItem(iconPath: 'assets/icons/property.svg', label: 'My Properties'),
          _buildNavItem(iconPath: 'assets/icons/user.svg', label: 'User'),
        ],
      ),
    );
  }

  Widget _buildNavItem({required String iconPath, required String label, bool isSelected = false}) {
    final color = isSelected ? const Color(0xFF5B5FEF) : const Color(0xFF6B7280);
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

  Widget _buildSectionTitle(String title, {required bool required}) {
    return RichText(
      text: TextSpan(
        text: title,
        style: GoogleFonts.inter(
          color: const Color(0xFF111827),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.inter(color: const Color(0xFFE5484D)),
                )
              ]
            : [],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool required,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, required: required),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
      ],
    );
  }

  Widget _buildSizeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Size', required: true),
            InkWell(
              onTap: () {},
              child: Text(
                'Auto from map',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sizeController,
          decoration: InputDecoration(
            hintText: 'Size Area',
            hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required bool required,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, required: required),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
          style: GoogleFonts.inter(color: const Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w500),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          elevation: 4,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PublishButtonWidget extends StatelessWidget {
  const _PublishButtonWidget({Key? key}) : super(key: key);

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
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 70.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.upload_outlined, color: Colors.white, size: 20),
              label: Text(
                'Publish Property',
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
