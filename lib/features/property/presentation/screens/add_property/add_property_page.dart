import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/core/media/image_compressor.dart';
import 'package:tilomnov/core/media/image_upload_policy.dart';
import 'package:tilomnov/shared/utils/image_rejection_message.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/home/utils/map/map_measurements.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';

import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/add_property_controller.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_form_input.dart';

import 'add_property_page_form_binding.dart';
import 'add_property_page_layout.dart';

/// Creates a listing, or edits [property] when one is given: the form
/// opens filled in and saving updates it instead of creating another.
class AddPropertyPage extends ConsumerStatefulWidget {
  final List<LatLng> boundaryPoints;
  final double propertyArea;
  final PropertyModel? property;

  const AddPropertyPage({
    super.key,
    required this.boundaryPoints,
    required this.propertyArea,
    this.property,
  });

  /// The edit form for [property], showing its drawn boundary, or
  /// [boundaryPoints] when the owner has just redrawn it on the map.
  factory AddPropertyPage.edit(
    PropertyModel property, {
    List<LatLng>? boundaryPoints,
    Key? key,
  }) {
    return AddPropertyPage(
      key: key,
      boundaryPoints: boundaryPoints ?? property.boundaryPoints,
      propertyArea: 0,
      property: property,
    );
  }

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
  final TextEditingController discountController = TextEditingController();

  String selectedPropertyType = 'Land';
  String selectedListingSetting = 'Sale';
  String selectedTitleType = 'Hard Title';

  /// 'percent' or 'amount'.
  String selectedDiscountType = 'percent';

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

  /// Whether the Archive button, not Publish, started the running save.
  bool isArchiving = false;

  final GlobalKey titleKey = GlobalKey();
  final GlobalKey priceKey = GlobalKey();
  final GlobalKey listingSettingsKey = GlobalKey();
  final GlobalKey landSizeKey = GlobalKey();
  final GlobalKey buildingSizeKey = GlobalKey();
  final GlobalKey unitSizeKey = GlobalKey();
  final GlobalKey discountKey = GlobalKey();

  final ImagePicker picker = ImagePicker();
  final List<XFile> selectedPhotos = [];

  bool get isEditing => widget.property != null;

  /// Whether the edited listing's boundary was redrawn and must be saved too.
  bool get isBoundaryChanged =>
      isEditing &&
      !listEquals(widget.boundaryPoints, widget.property!.boundaryPoints);

  /// The price the form sets: a Borey project's starting price, else the price.
  String get effectivePrice => selectedPropertyType == 'Borey'
      ? startingPriceController.text
      : priceController.text;

  /// Saved photos the owner has taken off in this edit. They stay on the
  /// listing until the changes are saved.
  final Set<String> removedPhotoUrls = {};

  /// Photos the listing already has and keeps; new ones go after them.
  List<String> get existingPhotoUrls => [
    for (final url in widget.property?.imageUrls ?? const <String>[])
      if (!removedPhotoUrls.contains(url)) url,
  ];

  void removeExistingPhoto(String url) =>
      setState(() => removedPhotoUrls.add(url));

  void restoreRemovedPhotos() => setState(removedPhotoUrls.clear);

  Future<void> pickImage(ImageSource source) async {
    final room =
        maxListingPhotos - existingPhotoUrls.length - selectedPhotos.length;
    if (room <= 0) {
      _sayPhotoLimit();
      return;
    }
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        // A limit of 1 is not allowed: one picture is picked on its own.
        picked = room == 1
            ? [?await picker.pickImage(source: source)]
            : await picker.pickMultiImage(limit: room);
      } else {
        final image = await picker.pickImage(source: source);
        picked = [?image];
      }
      if (picked.isEmpty) return;
      if (picked.length > room) _sayPhotoLimit();

      final prepared = await _prepare(picked.take(room).toList());
      if (prepared.isNotEmpty && mounted) {
        setState(() => selectedPhotos.addAll(prepared));
      }
    } catch (e) {
      AppLogger.debug('Error picking image: $e');
    }
  }

  void _sayPhotoLimit() {
    if (!mounted) return;
    AppPopup.showInfo(
      context,
      context.l10n.propertyPhotoLimit(maxListingPhotos),
    );
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

  @override
  void initState() {
    super.initState();
    final property = widget.property;
    if (property != null) {
      applyFormInput(PropertyFormInput.fromProperty(property));
      // Listings saved before sizes were stored as numbers lost theirs:
      // measure the boundary again rather than open the form empty.
      if (landSizeController.text.isEmpty) _measureBoundary();
    } else if (widget.propertyArea > 0) {
      landSizeController.text = _squareMeters(widget.propertyArea);
    }
  }

  /// "Auto from map": the land size of the drawn boundary.
  void fillLandSizeFromMap() {
    if (!_measureBoundary()) {
      AppPopup.showInfo(context, context.l10n.propertyDrawBoundaryFirst);
      return;
    }
    setState(() {});
  }

  /// Puts the boundary's area in the land size; false without a boundary.
  bool _measureBoundary() {
    final measurements = calculateMeasurements(widget.boundaryPoints);
    if (measurements == null) return false;
    landSizeController.text = _squareMeters(measurements.area);
    return true;
  }

  /// Sizes are typed and stored as plain m², e.g. "1670" or "83.5": a unit
  /// ("m²", "ha") in the field would not be saved as a number.
  static String _squareMeters(double area) =>
      PropertyFormat.size((area * 10).round() / 10);

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
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildAddPropertyLayout(context);
  }
}
