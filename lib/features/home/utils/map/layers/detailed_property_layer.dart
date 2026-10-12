import 'package:flutter/material.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';
import 'package:genie/features/home/utils/map/markers/label_markers.dart';
import 'package:genie/features/home/utils/map/markers/vertex_markers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Zoomed-in view: each property's boundary polygon, plus (for the one the
/// user is looking at) vertex numbers, edge lengths and area.
abstract final class DetailedPropertyLayer {
  static const _boundaryColor = Color(0xFF4F5BD5);

  static Future<void> build(
    List<List<LatLng>> detailedProps,
    List<bool> detailedPropsIsOwned,
    List<PropertyModel?> detailedPropModels,
    Set<Polygon> polygons,
    Set<Marker> markers,
    bool Function(int index, PropertyModel? property) isHighlighted,
    double currentZoom,
    void Function(int index, PropertyModel? property) onViewProperty,
    void Function(List<LatLng> propertyPoints) onEditProperty,
  ) async {
    for (var index = 0; index < detailedProps.length; index++) {
      final points = detailedProps[index];
      final model = detailedPropModels[index];
      final isViewed = isHighlighted(index, model);

      polygons.add(
        Polygon(
          polygonId: PolygonId('final_polygon_$index'),
          points: points,
          strokeColor: _boundaryColor,
          strokeWidth: isViewed ? 3 : 2,
          fillColor: _boundaryColor.withValues(alpha: isViewed ? 0.25 : 0.15),
          consumeTapEvents: true,
          onTap: () => onViewProperty(index, model),
        ),
      );

      if (isViewed) {
        await _addMeasurements(index, points, currentZoom, markers);
      }

      if (detailedPropsIsOwned[index]) {
        markers.add(
          Marker(
            markerId: MarkerId('edit_$index'),
            position: points[0],
            icon: await VertexMarkers.edit(),
            anchor: const Offset(1.2, 1.2),
            consumeTapEvents: true,
            onTap: () => onEditProperty(points),
          ),
        );
      }
    }
  }

  static Future<void> _addMeasurements(
    int index,
    List<LatLng> points,
    double currentZoom,
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
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      ),
    );
  }
}
