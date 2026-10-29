import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/home/utils/map/layers/boundary_label_layout.dart';
import 'package:tilomnov/features/home/utils/map/layers/layer_geometry.dart';
import 'package:tilomnov/features/home/utils/map/map_measurements.dart';
import 'package:tilomnov/features/home/utils/map/markers/label_markers.dart';
import 'package:tilomnov/features/home/utils/map/markers/vertex_markers.dart';

/// A boundary's measurements as map markers: its area, numbered corners and
/// side lengths. Labels with no room on screen at the zoom are left out (see
/// [BoundaryLabelLayout]); zooming in brings them back.
abstract final class BoundaryMeasurementMarkers {
  /// Adds the labels of the boundary [points], laid out for [zoom], to
  /// [markers], with ids keyed by [index]. The area goes on the centroid,
  /// just below a marker there when [hasCenterMarker]. With [areaInsideOnly]
  /// it is drawn only where it fits inside the plot, so it never hides a
  /// small or thin plot. Returns whether the area was drawn.
  static Future<bool> add({
    required int index,
    required List<LatLng> points,
    required double zoom,
    required Set<Marker> markers,
    bool hasCenterMarker = false,
    bool areaInsideOnly = false,
  }) async {
    final measurements = calculateMeasurements(points);
    if (measurements == null) return false;

    final area = measurements.area;
    // The map redraws these once per whole zoom level, so lay them out for
    // the furthest-out view of that level: zooming in only spreads them.
    final layoutZoom = zoom.floorToDouble();

    // Screen boxes already used, in order of importance: the area, then
    // corner numbers, then side lengths.
    final taken = <Rect>[];
    final areaLabel = formatArea(area);
    final areaFontSize = labelFontSize(area, zoom, isArea: true);
    final areaPosition = centroidOf(points);
    final areaAnchor = Offset(0.5, hasCenterMarker ? -0.9 : 0.5);
    final areaBox = BoundaryLabelLayout.markerRect(
      areaPosition,
      LabelMarkers.sizeOf(areaLabel, isArea: true, fontSize: areaFontSize),
      areaAnchor,
      layoutZoom,
    );
    final showArea =
        !areaInsideOnly ||
        BoundaryLabelLayout.fitsInside(areaBox, points, layoutZoom);
    if (showArea) {
      taken.add(areaBox);
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
    }

    await _addCorners(index, points, layoutZoom, taken, markers);
    if (measurements.sides.isNotEmpty) {
      await _addSideLabels(
        index,
        points,
        measurements.sides,
        zoom,
        layoutZoom,
        taken,
        markers,
      );
    }
    return showArea;
  }

  static Future<void> _addCorners(
    int index,
    List<LatLng> points,
    double layoutZoom,
    List<Rect> taken,
    Set<Marker> markers,
  ) async {
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
