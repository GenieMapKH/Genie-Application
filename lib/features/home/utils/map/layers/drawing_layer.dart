import 'package:flutter/material.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';
import 'package:genie/features/home/utils/map/markers/label_markers.dart';
import 'package:genie/features/home/utils/map/markers/vertex_markers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The boundary the user is drawing or editing on the map.
abstract final class DrawingLayer {
  static const _drawColor = Color(0xFFE5484D);

  static Future<void> build(
    List<LatLng> drawnPoints,
    bool isEditingPolygon,
    int? selectedVertexIndex,
    double currentZoom,
    Set<Polygon> polygons,
    Set<Marker> markers,
    Set<Polyline> polylines,
    BitmapDescriptor? pinIcon,
    BitmapDescriptor? smallWhiteDotIcon,
    void Function(int index, LatLng point) onUpdatePoint,
    void Function(int index, LatLng point) onInsertPoint,
    void Function(int? index) onSelectVertex,
    void Function() onClosePolygon,
  ) {
    if (isEditingPolygon) {
      return _buildEditing(
        drawnPoints,
        selectedVertexIndex,
        currentZoom,
        polygons,
        markers,
        smallWhiteDotIcon,
        onUpdatePoint,
        onInsertPoint,
        onSelectVertex,
      );
    }
    return _buildFreeDraw(
      drawnPoints,
      currentZoom,
      markers,
      polylines,
      pinIcon,
      smallWhiteDotIcon,
      onClosePolygon,
    );
  }

  /// A closed polygon whose corners can be dragged and whose edges can be
  /// split by dragging their midpoint.
  static Future<void> _buildEditing(
    List<LatLng> points,
    int? selectedVertexIndex,
    double currentZoom,
    Set<Polygon> polygons,
    Set<Marker> markers,
    BitmapDescriptor? smallWhiteDotIcon,
    void Function(int index, LatLng point) onUpdatePoint,
    void Function(int index, LatLng point) onInsertPoint,
    void Function(int? index) onSelectVertex,
  ) async {
    polygons.add(
      Polygon(
        polygonId: const PolygonId('edit_polygon'),
        points: points,
        strokeColor: _drawColor,
        strokeWidth: 2,
        fillColor: _drawColor.withValues(alpha: 0.1),
      ),
    );

    // Start every icon at once; they are awaited together below.
    final selectedVertexFuture = VertexMarkers.selected();
    final whiteDotFuture = VertexMarkers.smallWhiteDot();
    final labels = _startLabels(points, currentZoom);

    final selectedVertexIcon = await selectedVertexFuture;
    final whiteDot = smallWhiteDotIcon ?? await whiteDotFuture;
    final lengthIcons = await Future.wait(labels.lengthIcons);
    final areaIcon = await labels.areaIcon;

    if (labels.showEdges) {
      for (var i = 0; i < points.length; i++) {
        final midpoint = midpointOf(points[i], points[(i + 1) % points.length]);

        markers.add(
          Marker(
            markerId: MarkerId('edit_midpoint_$i'),
            position: midpoint,
            icon: whiteDot,
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: true,
            draggable: true,
            onDragStart: (position) => onInsertPoint(i + 1, position),
            onDrag: (position) => onUpdatePoint(i + 1, position),
            onDragEnd: (position) => onUpdatePoint(i + 1, position),
            onTap: () => onInsertPoint(i + 1, midpoint),
          ),
        );

        if (i < lengthIcons.length) {
          markers.add(
            Marker(
              markerId: MarkerId('edit_length_$i'),
              position: midpoint,
              icon: lengthIcons[i],
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 2,
            ),
          );
        }
      }
    }

    if (areaIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('edit_area_marker'),
          position: centroidOf(points),
          icon: areaIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
      );
    }

    for (var i = 0; i < points.length; i++) {
      final isSelected = i == selectedVertexIndex;
      markers.add(
        Marker(
          markerId: MarkerId('edit_point_$i'),
          position: points[i],
          consumeTapEvents: true,
          draggable: true,
          onDragStart: (_) {
            if (!isSelected) onSelectVertex(i);
          },
          onDrag: (position) => onUpdatePoint(i, position),
          onDragEnd: (position) => onUpdatePoint(i, position),
          onTap: () => onSelectVertex(i),
          icon: isSelected ? selectedVertexIcon : whiteDot,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: isSelected ? 10 : 5,
        ),
      );
    }
  }

  /// Starts rendering the edge-length and area labels without awaiting them.
  static _EditLabels _startLabels(List<LatLng> points, double currentZoom) {
    final measurements = calculateMeasurements(points);
    if (measurements == null) {
      return _EditLabels(showEdges: false, lengthIcons: [], areaIcon: null);
    }

    final area = measurements.area;
    final showEdges =
        measurements.sides.isNotEmpty &&
        shouldShowDetailedView(area, currentZoom);
    final edgeFontSize = labelFontSize(area, currentZoom, isArea: false);

    return _EditLabels(
      showEdges: showEdges,
      lengthIcons: [
        if (showEdges)
          for (var i = 0; i < points.length; i++)
            LabelMarkers.text(
              '${measurements.sides[i].toStringAsFixed(0)} m',
              fontSize: edgeFontSize,
            ),
      ],
      areaIcon: LabelMarkers.text(
        formatArea(area),
        isArea: true,
        fontSize: labelFontSize(area, currentZoom, isArea: true),
      ),
    );
  }

  /// Points being tapped in one by one, joined by a line with length labels.
  static Future<void> _buildFreeDraw(
    List<LatLng> points,
    double currentZoom,
    Set<Marker> markers,
    Set<Polyline> polylines,
    BitmapDescriptor? pinIcon,
    BitmapDescriptor? smallWhiteDotIcon,
    void Function() onClosePolygon,
  ) async {
    final fallbackIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );

    for (var i = 0; i < points.length; i++) {
      final isLastPoint = i == points.length - 1;

      markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: points[i],
          consumeTapEvents: true,
          // Tapping the first point closes the shape.
          onTap: () {
            if (i == 0 && points.length >= 3) onClosePolygon();
          },
          icon: isLastPoint
              ? (pinIcon ?? fallbackIcon)
              : (smallWhiteDotIcon ?? fallbackIcon),
          anchor: isLastPoint
              ? const Offset(0.5, 0.126)
              : const Offset(0.5, 0.5),
        ),
      );
    }

    if (points.length < 2) return;

    polylines.add(
      Polyline(
        polylineId: const PolylineId('drawn_polyline'),
        points: points,
        color: _drawColor,
        width: 2,
      ),
    );

    final edgeFontSize = labelFontSize(0, currentZoom, isArea: false);
    for (var i = 0; i < points.length - 1; i++) {
      final distance = calculateDistanceBetween(points[i], points[i + 1]);
      markers.add(
        Marker(
          markerId: MarkerId('free_length_$i'),
          position: midpointOf(points[i], points[i + 1]),
          icon: await LabelMarkers.text(
            '${distance.toStringAsFixed(0)} m',
            fontSize: edgeFontSize,
          ),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 2,
        ),
      );
    }
  }
}

class _EditLabels {
  final bool showEdges;
  final List<Future<BitmapDescriptor>> lengthIcons;
  final Future<BitmapDescriptor>? areaIcon;

  _EditLabels({
    required this.showEdges,
    required this.lengthIcons,
    required this.areaIcon,
  });
}
