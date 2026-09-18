import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

enum PropertyField {
  title,
  price,
  listingSettings,
  landSize,
  buildingSize,
  unitSize,
}

class ValidationResult {
  final bool isValid;
  final PropertyField? firstErrorField;

  const ValidationResult({required this.isValid, this.firstErrorField});
}

class AddPropertyFormState {
  final bool isLoading;
  
  const AddPropertyFormState({this.isLoading = false});
  
  AddPropertyFormState copyWith({bool? isLoading}) {
    return AddPropertyFormState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AddPropertyController extends AutoDisposeNotifier<AddPropertyFormState> {
  @override
  AddPropertyFormState build() {
    return const AddPropertyFormState();
  }

  ValidationResult validatePropertyForm({
    required String title,
    required String price,
    required String propertyType,
    required String listingSetting,
    required String landSize,
    required String buildingSize,
    required String unitSize,
  }) {
    PropertyField? firstErrorField;

    if (title.trim().isEmpty) firstErrorField ??= PropertyField.title;

    if (propertyType == 'Land' || propertyType.isEmpty) {
      if (price.trim().isEmpty) firstErrorField ??= PropertyField.price;
      if (listingSetting.isEmpty) firstErrorField ??= PropertyField.listingSettings;
      if (landSize.trim().isEmpty) firstErrorField ??= PropertyField.landSize;
    } else if (propertyType == 'House' || propertyType == 'Warehouse') {
      if (price.trim().isEmpty) firstErrorField ??= PropertyField.price;
      if (listingSetting.isEmpty) firstErrorField ??= PropertyField.listingSettings;
      if (landSize.trim().isEmpty) firstErrorField ??= PropertyField.landSize;
      if (buildingSize.trim().isEmpty) firstErrorField ??= PropertyField.buildingSize;
    } else if (propertyType == 'Building') {
      if (price.trim().isEmpty) firstErrorField ??= PropertyField.price;
      if (listingSetting.isEmpty) firstErrorField ??= PropertyField.listingSettings;
      if (landSize.trim().isEmpty) firstErrorField ??= PropertyField.landSize;
      if (buildingSize.trim().isEmpty) firstErrorField ??= PropertyField.buildingSize;
    } else if (propertyType == 'Condo') {
      if (price.trim().isEmpty) firstErrorField ??= PropertyField.price;
      if (listingSetting.isEmpty) firstErrorField ??= PropertyField.listingSettings;
      if (unitSize.trim().isEmpty) firstErrorField ??= PropertyField.unitSize;
    } else if (propertyType == 'Borey') {
      // Title is already checked
    } else if (propertyType == 'Business for Sale') {
      if (landSize.trim().isEmpty) firstErrorField ??= PropertyField.landSize;
      if (listingSetting.isEmpty) firstErrorField ??= PropertyField.listingSettings;
    }

    return ValidationResult(
      isValid: firstErrorField == null,
      firstErrorField: firstErrorField,
    );
  }

  Future<PropertyModel?> submitProperty({
    required String title,
    required String price,
    required String propertyType,
    required String landSize,
    required String buildingSize,
    required String unitSize,
    required List<LatLng> boundaryPoints,
    required List<XFile> selectedPhotos,
    String status = 'Active',
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final data = {
        'title': title.trim().isEmpty ? 'Untitled Property' : title.trim(),
        'price': double.tryParse(price.trim()) ?? 0,
        'propertyType': propertyType.isEmpty ? 'Land' : propertyType,
        if (landSize.trim().isNotEmpty) 'landSize': double.tryParse(landSize.trim()),
        if (buildingSize.trim().isNotEmpty) 'buildingSize': double.tryParse(buildingSize.trim()),
        if (unitSize.trim().isNotEmpty) 'unitSize': double.tryParse(unitSize.trim()),
        'status': status,
      };

      // 1. Create property
      var property = await repo.create(data);

      // 2. Attach boundary points if we have them
      if (boundaryPoints.isNotEmpty) {
        final points = boundaryPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
        property = await repo.updateBoundary(property.id, points);
      }

      // 3. Upload images if selected
      if (selectedPhotos.isNotEmpty) {
        property = await repo.uploadImages(property.id, selectedPhotos);
      }

      state = state.copyWith(isLoading: false);
      return property;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final addPropertyControllerProvider = AutoDisposeNotifierProvider<AddPropertyController, AddPropertyFormState>(() {
  return AddPropertyController();
});
