import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/presentation/providers/map_state_provider.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _square = [LatLng(0, 0), LatLng(0, 1), LatLng(1, 1), LatLng(1, 0)];

final _listing = PropertyModel.fromJson({
  'id': 'p-1',
  'title': 'Land',
  'price': '1',
  'propertyType': 'Land',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
  'images': [],
});

void main() {
  group('previewing scanned coordinates', () {
    test('keeps the boundary in the editor until saved', () {
      final notifier = MapStateNotifier()..startDrawing(initialPoints: _square);
      addTearDown(notifier.dispose);

      expect(notifier.state.isDrawing, isTrue);
      expect(notifier.state.isEditingPolygon, isTrue);
      expect(notifier.state.drawnPoints, _square);
      expect(notifier.state.finalizedProperties, isEmpty);
      expect(notifier.state.backupPoints, isNull);
    });

    test('cancelling does not leave an unpublished polygon on the map', () {
      final notifier = MapStateNotifier()
        ..startDrawing(initialPoints: _square)
        ..updatePoint(0, const LatLng(0.5, 0.5))
        ..cancelDrawing();
      addTearDown(notifier.dispose);

      expect(notifier.state.isDrawing, isFalse);
      expect(notifier.state.drawnPoints, isEmpty);
      expect(notifier.state.finalizedProperties, isEmpty);
    });

    test('a new scan clears the previous edit backup', () {
      final notifier = MapStateNotifier()
        ..editProperty(_square, null)
        ..startDrawing(initialPoints: _square)
        ..cancelDrawing();
      addTearDown(notifier.dispose);

      expect(notifier.state.backupPoints, isNull);
      expect(notifier.state.finalizedProperties, isEmpty);
    });
  });

  group('editing a saved listing', () {
    test('remembers which listing is being edited', () {
      final notifier = MapStateNotifier()..editProperty(_square, _listing);

      expect(notifier.state.editingProperty?.id, 'p-1');
      expect(notifier.state.isEditingPolygon, isTrue);
    });

    test('cancelling leaves no local copy of it on the map', () {
      final notifier = MapStateNotifier()
        ..editProperty(_square, _listing)
        ..cancelDrawing();

      expect(notifier.state.finalizedProperties, isEmpty);
      expect(notifier.state.editingProperty, isNull);
    });

    test('saving leaves no local copy of it on the map', () {
      final notifier = MapStateNotifier()
        ..editProperty(_square, _listing)
        ..finalizeDrawing();

      expect(notifier.state.finalizedProperties, isEmpty);
      expect(notifier.state.editingProperty, isNull);
    });

    test('a local polygon is put back when its edit is cancelled', () {
      final notifier = MapStateNotifier()
        ..editProperty(_square, null)
        ..cancelDrawing();

      expect(notifier.state.finalizedProperties, [_square]);
    });
  });

  group('dragging corners', () {
    test('a dragged corner remembers where it started and is selected '
        'only on the drop', () {
      final notifier = MapStateNotifier()
        ..editProperty(_square, null)
        ..selectVertex(0)
        ..startVertexDrag(2);

      expect(notifier.state.dragOrigin, const LatLng(1, 1));
      expect(notifier.state.selectedVertexIndex, 0);
    });

    test('a corner pulled out of an edge is inserted after it', () {
      final notifier = MapStateNotifier()
        ..editProperty(_square, null)
        ..startEdgeDrag(0, const LatLng(0, 0.5));

      expect(notifier.state.drawnPoints, hasLength(5));
      expect(notifier.state.drawnPoints[1], const LatLng(0, 0.5));
      expect(notifier.state.draggingVertex, 1);
      expect(notifier.state.dragStartEdge, 0);
      expect(notifier.state.dragOrigin, const LatLng(0, 0.5));
    });

    test('dropping a corner moves it and ends the drag', () {
      final notifier = MapStateNotifier()
        ..editProperty(_square, null)
        ..startVertexDrag(2)
        ..updatePoint(2, const LatLng(1.5, 1.5))
        ..endVertexDrag(2, const LatLng(2, 2));

      expect(notifier.state.drawnPoints[2], const LatLng(2, 2));
      expect(notifier.state.draggingVertex, isNull);
      expect(notifier.state.dragStartEdge, isNull);
      expect(notifier.state.dragOrigin, isNull);
      expect(notifier.state.selectedVertexIndex, 2);
    });
  });
}
