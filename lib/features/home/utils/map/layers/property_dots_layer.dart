import 'package:flutter/painting.dart';
import 'package:genie/features/home/utils/map/cluster_layout.dart';
import 'package:genie/features/home/utils/map/layers/clustered_layer.dart';
import 'package:genie/features/home/utils/map/markers/property_markers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Zoomed-in view: one tappable marker per listing (a price tag, or a dot for
/// a locally drawn polygon with no listing behind it).
abstract final class PropertyDotsLayer {
  /// Adds the markers, and returns where each listing is so the change from
  /// dots and bubbles can be animated. Like [ClusteredLayer], it leaves the
  /// selected listing out.
  static Future<ClusterLayout> build(
    double zoom,
    String newLabel,
    List<LatLng> allCentroids,
    List<PropertyModel?> allCentroidModels,
    Set<Marker> markers,
    BitmapDescriptor? greenDotIcon,
    BitmapDescriptor? selectedDotIcon,
    bool Function(int index, PropertyModel? property) isHighlighted,
    bool Function(int index) isOutlined,
    void Function(int index, PropertyModel? property) onViewProperty,
  ) async {
    final spotOf = <String, ClusterSpot>{};
    await Future.wait([
      for (var i = 0; i < allCentroids.length; i++)
        if (!isOutlined(i))
          _addMarker(
            newLabel,
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

    for (var i = 0; i < allCentroids.length; i++) {
      final property = allCentroidModels[i];
      if (isOutlined(i) || isHighlighted(i, property)) continue;
      final tag = property == null
          ? null
          : PropertyMarkers.priceTagLayout(
              price: property.formattedPrice,
              isNew: property.isNew,
              propertyType: property.propertyType,
              isVisited: property.isVisited,
              newLabel: newLabel,
            );
      spotOf[ClusteredLayer.listingKey(i, property)] = ClusterSpot(
        markerId: _markerId(i),
        position: allCentroids[i],
        count: 1,
        radius: PropertyMarkers.dotRadius,
        ring: PropertyMarkers.dotRing,
        lift: tag?.lift ?? 0,
        tag: tag,
      );
    }
    return ClusterLayout(zoomLevel: zoom.floor(), spotOf: spotOf);
  }

  static String _markerId(int index) => 'city_dot_$index';

  static Future<void> _addMarker(
    String newLabel,
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
    var anchor = const Offset(0.5, 0.5);
    if (property != null) {
      icon = await PropertyMarkers.priceTag(
        price: property.formattedPrice,
        isNew: property.isNew,
        isSelected: isSelected,
        propertyType: property.propertyType,
        isVisited: property.isVisited,
        newLabel: newLabel,
      );
      anchor = PropertyMarkers.priceTagAnchor(
        PropertyMarkers.priceTagLayout(
          price: property.formattedPrice,
          isNew: property.isNew,
          isSelected: isSelected,
          propertyType: property.propertyType,
          isVisited: property.isVisited,
          newLabel: newLabel,
        ),
      );
    } else {
      icon = isSelected
          ? (selectedDotIcon ?? BitmapDescriptor.defaultMarker)
          : (greenDotIcon ?? BitmapDescriptor.defaultMarker);
    }

    markers.add(
      Marker(
        markerId: MarkerId(_markerId(index)),
        position: position,
        icon: icon,
        anchor: anchor,
        consumeTapEvents: true,
        zIndexInt: isSelected ? 4 : 1,
        onTap: () => onViewProperty(index, property),
      ),
    );
  }
}
