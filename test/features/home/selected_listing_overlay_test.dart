import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:genie/features/home/utils/map/map_overlay_builder.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

PropertyModel _listing(String id, {bool withBoundary = true}) => PropertyModel(
  id: id,
  title: id,
  price: '39400',
  propertyType: 'Sell',
  status: 'Active',
  createdAt: DateTime(2020),
  lat: 11.55,
  lng: 104.92,
  boundaryPoints: withBoundary
      ? const [
          LatLng(11.5500, 104.9200),
          LatLng(11.5500, 104.9204),
          LatLng(11.5504, 104.9204),
          LatLng(11.5504, 104.9200),
        ]
      : const [],
);

Future<Set<String>> _markerIds(
  WidgetTester tester, {
  required List<PropertyModel> listings,
  required PropertyModel selected,
  required double zoom,
}) async {
  final overlays = await tester.runAsync(
    () => MapOverlayBuilder.buildListings(
      mapState: const MapState(),
      zoom: zoom,
      mapProperties: MapProperties(properties: listings),
      selectedProperty: selected,
      icons: const MapIcons(),
      callbacks: MapOverlayCallbacks(
        onSelectProperty: (_) {},
        onHighlightLocalPolygon: (_) {},
        onEditProperty: (_, _) {},
        onZoomToCluster: (_) {},
      ),
    ),
  );
  return {for (final m in overlays!.markers) m.markerId.value};
}

void main() {
  testWidgets(
    'a tapped listing shows its outline and sizes, not its price tag',
    (tester) async {
      final tapped = _listing('a');
      final other = _listing('b');
      final ids = await _markerIds(
        tester,
        listings: [tapped, other],
        selected: tapped,
        // Close enough for this 44 m square's sides to fit their lengths
        // beside the area label.
        zoom: 19,
      );

      expect(ids, isNot(contains('city_dot_0')));
      expect(ids, contains('city_dot_1'));
      expect(ids, contains('area_marker_0'));
      expect(
        ids,
        containsAll(['length_0_0', 'length_0_1', 'length_0_2', 'length_0_3']),
      );
    },
  );

  testWidgets('zoomed out, the tapped listing has no dot either', (
    tester,
  ) async {
    final tapped = _listing('a');
    final ids = await _markerIds(
      tester,
      listings: [tapped],
      selected: tapped,
      zoom: 12,
    );

    expect(ids, isNot(contains('dot_0')));
    expect(ids, contains('area_marker_0'));
  });

  testWidgets('a tapped listing without a boundary keeps its marker', (
    tester,
  ) async {
    final tapped = _listing('a', withBoundary: false);
    final ids = await _markerIds(
      tester,
      listings: [tapped],
      selected: tapped,
      zoom: 18,
    );

    expect(ids, contains('city_dot_0'));
  });
}
