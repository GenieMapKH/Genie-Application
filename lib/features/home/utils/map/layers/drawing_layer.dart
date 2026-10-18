import 'package:flutter/material.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/utils/map/layers/boundary_edit_layer.dart';
import 'package:genie/features/home/utils/map/layers/drawing_callbacks.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:genie/features/home/utils/map/map_measurements.dart';
import 'package:genie/features/home/utils/map/markers/label_markers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The boundary the user is drawing on the map, or (via [BoundaryEditLayer])
/// editing.
abstract final class DrawingLayer {
  static const _drawColor = Color(0xFFE5484D);

  static Future<void> build({
    required MapState mapState,
    required double zoom,
    required Set<Polygon> polygons,
    required Set<Marker> markers,
    required Set<Polyline> polylines,
    required BitmapDescriptor? pinIcon,
    required BitmapDescriptor? smallWhiteDotIcon,
    required DrawingCallbacks callbacks,
  }) {
    if (mapState.isEditingPolygon) {
      return BoundaryEditLayer.build(
        points: mapState.drawnPoints,
        selectedVertex: mapState.selectedVertexIndex,
        draggingVertex: mapState.draggingVertex,
        dragOrigin: mapState.dragOrigin,
        dragStartEdge: mapState.dragStartEdge,
        zoom: zoom,
        polygons: polygons,
        markers: markers,
        whiteDotIcon: smallWhiteDotIcon,
        callbacks: callbacks,
      );
    }
    return _buildFreeDraw(
      mapState.drawnPoints,
      zoom,
      markers,
      polylines,
      pinIcon,
      smallWhiteDotIcon,
      callbacks.onClosePolygon,
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
