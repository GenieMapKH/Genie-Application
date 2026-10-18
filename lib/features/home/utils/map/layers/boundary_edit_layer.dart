import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/utils/map/layers/drawing_callbacks.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';
import 'package:genie/features/home/utils/map/markers/label_markers.dart';
import 'package:genie/features/home/utils/map/markers/vertex_markers.dart';

/// A closed boundary being edited: corners can be dragged, and each edge has
/// a "+" handle that adds a corner when tapped or dragged. Edge lengths and
/// the area follow a dragged corner live.
///
/// Kept smooth by touching as little as possible per move: the handle under
/// the finger is rebuilt exactly as it was when the drag began (so the map
/// leaves it alone), untouched corners and labels come out equal to last
/// time (so the map skips them), and only the moving edges get new labels.
abstract final class BoundaryEditLayer {
  static const _drawColor = Color(0xFFE5484D);

  static Future<void> build({
    required List<LatLng> points,
    required int? selectedVertex,
    required int? draggingVertex,
    required LatLng? dragOrigin,
    required int? dragStartEdge,
    required double zoom,
    required Set<Polygon> polygons,
    required Set<Marker> markers,
    required BitmapDescriptor? whiteDotIcon,
    required DrawingCallbacks callbacks,
  }) async {
    polygons.add(
      Polygon(
        polygonId: const PolygonId('edit_polygon'),
        points: points,
        strokeColor: _drawColor,
        strokeWidth: 2,
        fillColor: _drawColor.withValues(alpha: 0.1),
      ),
    );

    final selectedIcon = await VertexMarkers.selected();
    final whiteDot = whiteDotIcon ?? await VertexMarkers.smallWhiteDot();
    final addIcon = await VertexMarkers.addCorner();

    for (var i = 0; i < points.length; i++) {
      final isDragged = i == draggingVertex;
      if (isDragged && dragStartEdge != null) {
        markers.add(
          _cornerHandle(dragStartEdge, dragOrigin!, addIcon, callbacks),
        );
        continue;
      }
      markers.add(
        _corner(
          i,
          isDragged ? dragOrigin! : points[i],
          i == selectedVertex ? selectedIcon : whiteDot,
          isSelected: i == selectedVertex,
          callbacks: callbacks,
        ),
      );
    }

    // The other "+" handles would have to chase the moving edges; they come
    // back on the drop.
    if (draggingVertex == null) {
      for (var i = 0; i < points.length; i++) {
        final next = points[(i + 1) % points.length];
        markers.add(
          _cornerHandle(i, midpointOf(points[i], next), addIcon, callbacks),
        );
      }
    }

    await _addLabels(points, zoom, markers);
  }

  static Marker _corner(
    int index,
    LatLng position,
    BitmapDescriptor icon, {
    required bool isSelected,
    required DrawingCallbacks callbacks,
  }) {
    return Marker(
      markerId: MarkerId('edit_point_$index'),
      position: position,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      zIndexInt: isSelected ? 10 : 5,
      consumeTapEvents: true,
      draggable: true,
      onDragStart: (_) => callbacks.onStartVertexDrag(index),
      onDrag: (position) => callbacks.onUpdatePoint(index, position),
      onDragEnd: (position) => callbacks.onEndVertexDrag(index, position),
      onTap: () => callbacks.onSelectVertex(index),
    );
  }

  /// The "+" on edge [edge]; dragging it pulls out corner `edge + 1`.
  static Marker _cornerHandle(
    int edge,
    LatLng midpoint,
    BitmapDescriptor icon,
    DrawingCallbacks callbacks,
  ) {
    final newCorner = edge + 1;
    return Marker(
      markerId: MarkerId('edit_midpoint_$edge'),
      position: midpoint,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 4,
      consumeTapEvents: true,
      draggable: true,
      onDragStart: (_) => callbacks.onStartEdgeDrag(edge, midpoint),
      onDrag: (position) => callbacks.onUpdatePoint(newCorner, position),
      onDragEnd: (position) => callbacks.onEndVertexDrag(newCorner, position),
      onTap: () => callbacks.onInsertPoint(newCorner, midpoint),
    );
  }

  static Future<void> _addLabels(
    List<LatLng> points,
    double zoom,
    Set<Marker> markers,
  ) async {
    final measurements = calculateMeasurements(points);
    if (measurements == null) return;

    final area = measurements.area;
    final showEdges =
        measurements.sides.isNotEmpty && shouldShowDetailedView(area, zoom);

    // Labels are cached by text, so only the edges that changed length are
    // drawn anew; whole metres keep that to a few per drag.
    final edgeFontSize = labelFontSize(area, zoom, isArea: false);
    final icons = await Future.wait([
      if (showEdges)
        for (final side in measurements.sides)
          LabelMarkers.text(
            '${side.toStringAsFixed(0)} m',
            fontSize: edgeFontSize,
          ),
      LabelMarkers.text(
        formatArea(area),
        isArea: true,
        fontSize: labelFontSize(area, zoom, isArea: true),
      ),
    ]);

    if (showEdges) {
      for (var i = 0; i < points.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('edit_length_$i'),
            position: midpointOf(points[i], points[(i + 1) % points.length]),
            icon: icons[i],
            // Just below the edge's "+" handle, which sits on the midpoint.
            anchor: const Offset(0.5, -0.5),
            zIndexInt: 2,
          ),
        );
      }
    }

    markers.add(
      Marker(
        markerId: const MarkerId('edit_area_marker'),
        position: centroidOf(points),
        icon: icons.last,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
      ),
    );
  }
}
