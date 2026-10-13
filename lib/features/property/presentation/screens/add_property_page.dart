import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/core/media/image_compressor.dart';
import 'package:genie/core/media/image_upload_policy.dart';
import 'package:genie/shared/utils/image_rejection_message.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';

import 'add_property_page_layout.dart';

class AddPropertyPage extends ConsumerStatefulWidget {
  final List<LatLng> boundaryPoints;
  final double propertyArea;

  const AddPropertyPage({
    super.key,
    required this.boundaryPoints,
    required this.propertyArea,
  });

  @override
  ConsumerState<AddPropertyPage> createState() => AddPropertyPageState();
}

class AddPropertyPageState extends ConsumerState<AddPropertyPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController landSizeController = TextEditingController();
  final TextEditingController buildingSizeController = TextEditingController();
  final TextEditingController unitSizeController = TextEditingController();
  final TextEditingController maintenanceFeeController =
      TextEditingController();

  // Borey specific controllers
  final TextEditingController developerNameController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController totalProjectAreaController =
      TextEditingController();
  final TextEditingController totalUnitsTextController =
      TextEditingController();
  final TextEditingController startingPriceController = TextEditingController();

  // Business for Sale specific controllers
  final TextEditingController monthlyRentController = TextEditingController();
  final TextEditingController leaseRemainingController =
      TextEditingController();
  final TextEditingController equipmentIncludedController =
      TextEditingController();
  final TextEditingController reasonForSellingController =
      TextEditingController();

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedPropertyType = 'Land';
  String selectedListingSetting = 'Sale';
  String selectedTitleType = 'Hard Title';

  String? selectedBedrooms;
  String? selectedBathrooms;
  String? selectedFloors;
  String? selectedFloorNumber;
  String? selectedParking;
  String? selectedFurnished;
  String? selectedBuildingType;
  String? selectedTotalUnits;
  String? selectedBalcony;
  String? selectedCompletionStatus;
  String? selectedViewType;

  // New selected states for Borey & Business
  String? selectedProjectType;
  String? selectedLeaseUnit;
  final Set<String> selectedKeywords = {};

  bool hasAttemptedSubmit = false;
  bool isLoading = false;

  final GlobalKey titleKey = GlobalKey();
  final GlobalKey priceKey = GlobalKey();
  final GlobalKey listingSettingsKey = GlobalKey();
  final GlobalKey landSizeKey = GlobalKey();
  final GlobalKey buildingSizeKey = GlobalKey();
  final GlobalKey unitSizeKey = GlobalKey();

  final ImagePicker picker = ImagePicker();
  final List<XFile> selectedPhotos = [];

  Future<void> pickImage(ImageSource source) async {
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await picker.pickMultiImage();
      } else {
        final image = await picker.pickImage(source: source);
        picked = [?image];
      }
      if (picked.isEmpty) return;

      final prepared = await _prepare(picked);
      if (prepared.isNotEmpty && mounted) {
        setState(() => selectedPhotos.addAll(prepared));
      }
    } catch (e) {
      AppLogger.debug('Error picking image: $e');
    }
  }

  /// Compresses each picture to a small JPEG. One that is too large or
  /// unreadable is left out, and the user is told why.
  Future<List<XFile>> _prepare(List<XFile> pictures) async {
    final prepared = <XFile>[];
    for (final picture in pictures) {
      try {
        final image = await ImageCompressor.native.compress(
          picture,
          ImageUploadPolicy.propertyPhoto,
        );
        prepared.add(image.toXFile());
      } on ImageRejectedException catch (e) {
        if (!mounted) break;
        AppPopup.showError(
          context,
          imageRejectionMessage(context.l10n, e.reason),
        );
      }
    }
    return prepared;
  }

  final List<Map<String, dynamic>> keywords = [
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
      landSizeController.text = formatArea(widget.propertyArea);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    landSizeController.dispose();
    buildingSizeController.dispose();
    unitSizeController.dispose();
    maintenanceFeeController.dispose();
    developerNameController.dispose();
    projectNameController.dispose();
    totalProjectAreaController.dispose();
    totalUnitsTextController.dispose();
    startingPriceController.dispose();
    monthlyRentController.dispose();
    leaseRemainingController.dispose();
    equipmentIncludedController.dispose();
    reasonForSellingController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildAddPropertyLayout(context);
  }
}
