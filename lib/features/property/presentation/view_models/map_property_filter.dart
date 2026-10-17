import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/property/data/models/property_model.dart';

/// What the pills under the map's search bar narrow the listings to. A null
/// field means "any".
class MapPropertyFilter {
  /// As stored, e.g. 'Business for Sale'.
  final String? propertyType;

  /// 'Sale', 'Rent' or 'To Let'.
  final String? listingType;

  const MapPropertyFilter({this.propertyType, this.listingType});

  bool get isEmpty => propertyType == null && listingType == null;

  bool matches(PropertyModel property) =>
      (propertyType == null || property.propertyType == propertyType) &&
      (listingType == null || property.listingType == listingType);

  /// Picking the selected value again clears it.
  MapPropertyFilter toggleType(String type) => MapPropertyFilter(
    propertyType: propertyType == type ? null : type,
    listingType: listingType,
  );

  MapPropertyFilter toggleListing(String listing) => MapPropertyFilter(
    propertyType: propertyType,
    listingType: listingType == listing ? null : listing,
  );

  @override
  bool operator ==(Object other) =>
      other is MapPropertyFilter &&
      other.propertyType == propertyType &&
      other.listingType == listingType;

  @override
  int get hashCode => Object.hash(propertyType, listingType);
}

final mapPropertyFilterProvider = StateProvider<MapPropertyFilter>(
  (ref) => const MapPropertyFilter(),
);
