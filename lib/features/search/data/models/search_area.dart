import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/property/data/models/property_model.dart';

/// What the map shows after a place or a person was chosen: the region to
/// look at and the listings that belong to it.
class SearchArea {
  final List<PropertyModel> properties;

  /// The region the camera should frame; null when there is nothing to show
  /// on the map (a person whose listings have no location).
  final LatLngBounds? bounds;

  const SearchArea({required this.properties, this.bounds});

  /// Places frame their whole search region, even when listings cluster in a corner.
  LatLngBounds? get framing => bounds ?? SearchArea.around(properties).bounds;

  /// Google supplies a search viewport, rather than an administrative boundary.
  List<LatLng> get outline => bounds == null
      ? const []
      : [
          bounds!.southwest,
          LatLng(bounds!.northeast.latitude, bounds!.southwest.longitude),
          bounds!.northeast,
          LatLng(bounds!.southwest.latitude, bounds!.northeast.longitude),
        ];

  /// The smallest region holding every located listing in [properties].
  factory SearchArea.around(List<PropertyModel> properties) {
    double? minLat, maxLat, minLng, maxLng;
    for (final property in properties) {
      final lat = property.lat, lng = property.lng;
      if (lat == null || lng == null) continue;
      minLat = minLat == null || lat < minLat ? lat : minLat;
      maxLat = maxLat == null || lat > maxLat ? lat : maxLat;
      minLng = minLng == null || lng < minLng ? lng : minLng;
      maxLng = maxLng == null || lng > maxLng ? lng : maxLng;
    }

    return SearchArea(
      properties: properties,
      bounds: minLat == null
          ? null
          : LatLngBounds(
              southwest: LatLng(minLat, minLng!),
              northeast: LatLng(maxLat!, maxLng!),
            ),
    );
  }
}
