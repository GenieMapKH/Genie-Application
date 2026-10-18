import 'package:flutter/material.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';
import 'package:genie/features/home/utils/map/markers/label_markers.dart';
import 'package:genie/features/home/utils/map/markers/vertex_markers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The tapped listing's real shape: its boundary polygon with vertex numbers,
/// edge lengths and area. Drawn at every zoom level.
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

    await _addMeasurements(index, points, zoom, hasCenterMarker, markers);

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

  static Future<void> _addMeasurements(
    int index,
    List<LatLng> points,
    double currentZoom,
    bool hasCenterMarker,
    Set<Marker> markers,
  ) async {
    final measurements = calculateMeasurements(points);
    if (measurements == null) return;

    final area = measurements.area;

    for (var i = 0; i < points.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('vertex_${index}_$i'),
          position: points[i],
          icon: await VertexMarkers.numbered(i + 1),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
        ),
      );
    }

    if (measurements.sides.isEmpty) return;

    final edgeFontSize = labelFontSize(area, currentZoom, isArea: false);
    for (var i = 0; i < points.length; i++) {
      final next = points[(i + 1) % points.length];
      markers.add(
        Marker(
          markerId: MarkerId('length_${index}_$i'),
          position: midpointOf(points[i], next),
          icon: await LabelMarkers.text(
            '${measurements.sides[i].toStringAsFixed(0)} m',
            fontSize: edgeFontSize,
          ),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 2,
        ),
      );
    }

    markers.add(
      Marker(
        markerId: MarkerId('area_marker_$index'),
        position: centroidOf(points),
        icon: await LabelMarkers.text(
          formatArea(area),
          isArea: true,
          fontSize: labelFontSize(area, currentZoom, isArea: true),
        ),
        // Just below a marker on the centroid; on the centroid without one.
        anchor: Offset(0.5, hasCenterMarker ? -0.9 : 0.5),
        zIndexInt: 1,
      ),
    );
  }
}
