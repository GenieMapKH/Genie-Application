import 'package:flutter/painting.dart';
import 'package:genie/features/home/utils/map/markers/property_markers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mid-zoom view: one tappable marker per listing (a price tag, or a dot when
/// the property details are not loaded).
abstract final class PropertyDotsLayer {
  static Future<void> build(
    List<LatLng> allCentroids,
    List<PropertyModel?> allCentroidModels,
    Set<Marker> markers,
    BitmapDescriptor? greenDotIcon,
    BitmapDescriptor? selectedDotIcon,
    bool Function(int index, PropertyModel? property) isHighlighted,
    void Function(int index, PropertyModel? property) onViewProperty,
  ) async {
    await Future.wait([
      for (var i = 0; i < allCentroids.length; i++)
        _addMarker(
          i,
          allCentroids[i],
          allCentroidModels[i],
          markers,
          greenDotIcon,
          selectedDotIcon,
          isHighlighted,
          onViewProperty,
        ),
    ]);
  }

  static Future<void> _addMarker(
    int index,
    LatLng position,
    PropertyModel? property,
    Set<Marker> markers,
    BitmapDescriptor? greenDotIcon,
    BitmapDescriptor? selectedDotIcon,
    bool Function(int index, PropertyModel? property) isHighlighted,
    void Function(int index, PropertyModel? property) onViewProperty,
  ) async {
    final isSelected = isHighlighted(index, property);

    final BitmapDescriptor icon;
    if (property != null) {
      icon = await PropertyMarkers.priceTag(
        price: property.formattedPrice,
        isNew: property.isNew,
        isSelected: isSelected,
        propertyType: property.propertyType,
        isVisited: property.isVisited,
      );
    } else {
      icon = isSelected
          ? (selectedDotIcon ?? BitmapDescriptor.defaultMarker)
          : (greenDotIcon ?? BitmapDescriptor.defaultMarker);
    }

    markers.add(
      Marker(
        markerId: MarkerId('city_dot_$index'),
        position: position,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
        zIndexInt: isSelected ? 4 : 1,
        onTap: () => onViewProperty(index, property),
      ),
    );
  }
}
