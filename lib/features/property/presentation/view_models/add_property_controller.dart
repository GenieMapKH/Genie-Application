import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_form_input.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';

enum PropertyField {
  title,
  price,
  listingSettings,
  landSize,
  buildingSize,
  unitSize,
  discount,
}

/// A discount is optional; when given it must leave a price above zero: a
/// percentage below 100, or an amount below [price]. Mirrors the server.
bool isValidDiscount({
  required String discount,
  required String discountType,
  required String price,
}) {
  final text = discount.replaceAll(',', '').trim();
  if (text.isEmpty) return true;
  final value = double.tryParse(text);
  if (value == null || value <= 0) return false;
  if (discountType == 'percent') return value < 100;
  final priceValue = double.tryParse(price.replaceAll(',', '').trim()) ?? 0;
  return value < priceValue;
}

/// The most photos a listing can have. The server refuses more.
const maxListingPhotos = 30;

class ValidationResult {
  final bool isValid;
  final PropertyField? firstErrorField;

  const ValidationResult({required this.isValid, this.firstErrorField});
}

class AddPropertyFormState {
  final bool isLoading;

  const AddPropertyFormState({this.isLoading = false});

  AddPropertyFormState copyWith({bool? isLoading}) {
    return AddPropertyFormState(isLoading: isLoading ?? this.isLoading);
  }
}

class AddPropertyController extends AutoDisposeNotifier<AddPropertyFormState> {
  @override
  AddPropertyFormState build() {
    return const AddPropertyFormState();
  }

  /// Fields that must be filled, in the order errors are reported, per
  /// property type. The title is always required and checked first.
  static const _requiredFieldsByType = <String, List<PropertyField>>{
    'Land': [
      PropertyField.price,
      PropertyField.listingSettings,
      PropertyField.landSize,
    ],
    'House': [
      PropertyField.price,
      PropertyField.listingSettings,
      PropertyField.landSize,
      PropertyField.buildingSize,
    ],
    'Warehouse': [
      PropertyField.price,
      PropertyField.listingSettings,
      PropertyField.landSize,
      PropertyField.buildingSize,
    ],
    'Building': [
      PropertyField.price,
      PropertyField.listingSettings,
      PropertyField.landSize,
      PropertyField.buildingSize,
    ],
    'Condo': [
      PropertyField.price,
      PropertyField.listingSettings,
      PropertyField.unitSize,
    ],
    'Business for Sale': [
      PropertyField.price,
      PropertyField.listingSettings,
      PropertyField.landSize,
    ],
    'Borey': [],
  };

  ValidationResult validatePropertyForm({
    required String title,
    required String price,
    required String propertyType,
    required String listingSetting,
    required String landSize,
    required String buildingSize,
    required String unitSize,
    String discount = '',
    String discountType = 'percent',
  }) {
    final values = {
      PropertyField.title: title,
      PropertyField.price: price,
      PropertyField.listingSettings: listingSetting,
      PropertyField.landSize: landSize,
      PropertyField.buildingSize: buildingSize,
      PropertyField.unitSize: unitSize,
    };

    // No type chosen yet is treated as Land, the default type.
    final type = propertyType.isEmpty ? 'Land' : propertyType;
    final required = [PropertyField.title, ...?_requiredFieldsByType[type]];

    final discountOk = isValidDiscount(
      discount: discount,
      discountType: discountType,
      price: price,
    );
    final firstErrorField =
        required.where((field) => values[field]!.trim().isEmpty).firstOrNull ??
        (discountOk ? null : PropertyField.discount);

    return ValidationResult(
      isValid: firstErrorField == null,
      firstErrorField: firstErrorField,
    );
  }

  /// Creates the listing from [input], then attaches its boundary and photos.
  Future<PropertyModel?> submitProperty({
    required PropertyFormInput input,
    required List<LatLng> boundaryPoints,
    required List<XFile> selectedPhotos,
    String status = 'Active',
  }) {
    return _whileLoading(() async {
      final repo = ref.read(propertyRepositoryProvider);
      var property = await repo.create({
        ...input.toRequestBody(),
        'status': status,
      });

      if (boundaryPoints.isNotEmpty) {
        property = await repo.updateBoundary(
          property.id,
          _boundaryBody(boundaryPoints),
        );
      }

      if (selectedPhotos.isNotEmpty) {
        property = await repo.uploadImages(property.id, selectedPhotos);
      }
      return property;
    });
  }

  /// Saves the edited form over listing [propertyId], takes off
  /// [removedPhotoUrls] and adds [newPhotos]. Given [boundaryPoints], the
  /// boundary is replaced too and the server moves the pin to its centre;
  /// otherwise the location stays as it is. Its status stays as it is.
  Future<PropertyModel> updateProperty({
    required String propertyId,
    required PropertyFormInput input,
    required List<XFile> newPhotos,
    List<String> removedPhotoUrls = const [],
    List<LatLng>? boundaryPoints,
  }) {
    return _whileLoading(() async {
      final repo = ref.read(propertyRepositoryProvider);
      var property = await repo.update(propertyId, input.toRequestBody());
      if (boundaryPoints != null) {
        property = await repo.updateBoundary(
          propertyId,
          _boundaryBody(boundaryPoints),
        );
      }
      // Removed first, so the new photos fit under the per-listing limit.
      if (removedPhotoUrls.isNotEmpty) {
        property = await repo.removeImages(propertyId, removedPhotoUrls);
      }
      if (newPhotos.isNotEmpty) {
        property = await repo.uploadImages(propertyId, newPhotos);
      }
      return property;
    });
  }

  static List<Map<String, double>> _boundaryBody(List<LatLng> points) => [
    for (final p in points) {'lat': p.latitude, 'lng': p.longitude},
  ];

  /// Runs [work], a save of the user's listing, then tells whatever shows
  /// their listings to read them again: even a save that failed half way
  /// (created, but a photo upload failed) changed them.
  Future<T> _whileLoading<T>(Future<T> Function() work) async {
    state = state.copyWith(isLoading: true);
    try {
      return await work();
    } finally {
      state = state.copyWith(isLoading: false);
      ownListingsChanged(ref);
    }
  }
}

final addPropertyControllerProvider =
    AutoDisposeNotifierProvider<AddPropertyController, AddPropertyFormState>(
      () {
        return AddPropertyController();
      },
    );
