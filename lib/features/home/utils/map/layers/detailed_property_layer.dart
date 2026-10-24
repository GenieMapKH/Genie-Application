import 'package:flutter/material.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/home/utils/map/layers/boundary_label_layout.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';
import 'package:genie/features/home/utils/map/markers/label_markers.dart';
import 'package:genie/features/home/utils/map/markers/vertex_markers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The tapped listing's real shape: its boundary polygon with vertex numbers,
/// edge lengths and area. Drawn at every zoom level; numbers and lengths
/// with no room on screen are left out (see [BoundaryLabelLayout]).
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
    // The map redraws these once per whole zoom level, so lay them out for
    // the furthest-out view of that level: zooming in only spreads them.
    final layoutZoom = currentZoom.floorToDouble();

    // Screen boxes already used, in order of importance: the area, then
    // corner numbers, then side lengths.
    final taken = <Rect>[];
    final areaLabel = formatArea(area);
    final areaFontSize = labelFontSize(area, currentZoom, isArea: true);
    final areaPosition = centroidOf(points);
    // Just below a marker on the centroid; on the centroid without one.
    final areaAnchor = Offset(0.5, hasCenterMarker ? -0.9 : 0.5);
    taken.add(
      BoundaryLabelLayout.markerRect(
        areaPosition,
        LabelMarkers.sizeOf(areaLabel, isArea: true, fontSize: areaFontSize),
        areaAnchor,
        layoutZoom,
      ),
    );
    markers.add(
      Marker(
        markerId: MarkerId('area_marker_$index'),
        position: areaPosition,
        icon: await LabelMarkers.text(
          areaLabel,
          isArea: true,
          fontSize: areaFontSize,
        ),
        anchor: areaAnchor,
        zIndexInt: 1,
      ),
    );

    for (final i in BoundaryLabelLayout.placeCorners(
      points,
      layoutZoom,
      taken,
    )) {
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
    await _addSideLabels(
      index,
      points,
      measurements.sides,
      currentZoom,
      layoutZoom,
      taken,
      markers,
    );
  }

  static Future<void> _addSideLabels(
    int index,
    List<LatLng> points,
    List<double> sides,
    double currentZoom,
    double layoutZoom,
    List<Rect> taken,
    Set<Marker> markers,
  ) async {
    final fontSize = labelFontSize(0, currentZoom, isArea: false);
    final labels = [for (final side in sides) '${side.toStringAsFixed(0)} m'];
    final placed = BoundaryLabelLayout.placeSides(points, layoutZoom, [
      for (final label in labels)
        LabelMarkers.sizeOf(label, fontSize: fontSize),
    ], taken);

    for (final MapEntry(key: i, value: position) in placed.entries) {
      markers.add(
        Marker(
          markerId: MarkerId('length_${index}_$i'),
          position: position,
          icon: await LabelMarkers.text(labels[i], fontSize: fontSize),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 2,
        ),
      );
    }
  }
}
