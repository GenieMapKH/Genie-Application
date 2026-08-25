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

part 'add_property_page_logic.dart';
part 'add_property_page_layout.dart';
part 'add_property_page_forms_dynamic.dart';
part 'add_property_page_forms_base.dart';

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
    return _buildAddPropertyLayout(context);
  }
}
