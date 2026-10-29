import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/utils/map/layers/boundary_edit_layer.dart';
import 'package:tilomnov/features/home/utils/map/layers/drawing_callbacks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Roughly a 110 m square, small enough to show edge lengths at zoom 19.
const _square = [
  LatLng(11.5, 104.9),
  LatLng(11.5, 104.901),
  LatLng(11.501, 104.901),
  LatLng(11.501, 104.9),
];

final _callbacks = DrawingCallbacks(
  onUpdatePoint: (_, _) {},
  onInsertPoint: (_, _) {},
  onSelectVertex: (_) {},
  onClosePolygon: () {},
  onStartVertexDrag: (_) {},
  onStartEdgeDrag: (_, _) {},
  onEndVertexDrag: (_, _) {},
);

Future<Map<String, Marker>> _build(
  List<LatLng> points, {
  int? draggingVertex,
  LatLng? dragOrigin,
  int? dragStartEdge,
}) async {
  final markers = <Marker>{};
  await BoundaryEditLayer.build(
    points: points,
    selectedVertex: null,
    draggingVertex: draggingVertex,
    dragOrigin: dragOrigin,
    dragStartEdge: dragStartEdge,
    zoom: 19,
    polygons: {},
    markers: markers,
    whiteDotIcon: null,
    callbacks: _callbacks,
  );
  return {for (final m in markers) m.markerId.value: m};
}

void main() {
  testWidgets('a dragged corner is left exactly as it was while the edge '
      'lengths follow it', (tester) async {
    await tester.runAsync(() async {
      final before = await _build(_square);

      final moved = List.of(_square)..[2] = const LatLng(11.502, 104.902);
      final during = await _build(
        moved,
        draggingVertex: 2,
        dragOrigin: _square[2],
      );

      expect(during['edit_point_2'], before['edit_point_2']);
      expect(during['edit_point_0'], before['edit_point_0']);
      // The two edges touching the corner change; the far ones do not.
      expect(during['edit_length_1'], isNot(before['edit_length_1']));
      expect(during['edit_length_2'], isNot(before['edit_length_2']));
      expect(during['edit_length_0'], before['edit_length_0']);
      expect(
        during.keys.where((id) => id.startsWith('edit_midpoint')),
        isEmpty,
      );
    });
  });

  testWidgets('a corner pulled from a "+" keeps that handle while it moves', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final before = await _build(_square);
      final handle = before['edit_midpoint_0']!;

      final pulled = List.of(_square)
        ..insert(1, const LatLng(11.4995, 104.9005));
      final during = await _build(
        pulled,
        draggingVertex: 1,
        dragOrigin: handle.position,
        dragStartEdge: 0,
      );

      expect(during['edit_midpoint_0'], handle);
      expect(during, contains('edit_length_4'));
    });
  });
}
