import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// What the drawing and boundary-editing handles do when touched.
class DrawingCallbacks {
  final void Function(int index, LatLng point) onUpdatePoint;
  final void Function(int index, LatLng point) onInsertPoint;
  final void Function(int? index) onSelectVertex;
  final VoidCallback onClosePolygon;
  final void Function(int index) onStartVertexDrag;
  final void Function(int edge, LatLng point) onStartEdgeDrag;
  final void Function(int index, LatLng point) onEndVertexDrag;

  const DrawingCallbacks({
    required this.onUpdatePoint,
    required this.onInsertPoint,
    required this.onSelectVertex,
    required this.onClosePolygon,
    required this.onStartVertexDrag,
    required this.onStartEdgeDrag,
    required this.onEndVertexDrag,
  });
}
