import 'package:flutter/material.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/utils/map/layers/boundary_measurement_markers.dart';
import 'package:tilomnov/features/home/utils/map/markers/vertex_markers.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The tapped listing's real shape: its boundary polygon with vertex numbers,
/// edge lengths and area. Drawn at every zoom level; numbers and lengths
/// with no room on screen are left out (see [BoundaryMeasurementMarkers]).
abstract final class DetailedPropertyLayer {
  // Gold reads on both the default and the satellite map.
  static final _boundaryColor = AppColors.light.highlight;

  static Future<void> build({
    required int index,
    required List<LatLng> points,
    required PropertyModel? property,
    required bool isOwned,
    required bool hasCenterMarker,
    required double zoom,
    required Set<Polygon> polygons,
    required Set<Marker> markers,
    required void Function(int index, PropertyModel? property) onViewProperty,
    required void Function(List<LatLng> points, PropertyModel? property)
    onEditProperty,
  }) async {
    polygons.add(
      Polygon(
        polygonId: PolygonId('final_polygon_$index'),
        points: points,
        strokeColor: _boundaryColor,
        strokeWidth: 3,
        fillColor: _boundaryColor.withValues(alpha: 0.25),
        consumeTapEvents: true,
        onTap: () => onViewProperty(index, property),
      ),
    );

    await BoundaryMeasurementMarkers.add(
      index: index,
      points: points,
      zoom: zoom,
      markers: markers,
      hasCenterMarker: hasCenterMarker,
    );

    if (isOwned) {
      markers.add(
        Marker(
          markerId: MarkerId('edit_$index'),
          position: points[0],
          icon: await VertexMarkers.edit(),
          anchor: const Offset(1.2, 1.2),
          consumeTapEvents: true,
          onTap: () => onEditProperty(points, property),
        ),
      );
    }
  }
}
