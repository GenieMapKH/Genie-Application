import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/presentation/providers/map_properties_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/map_state_provider.dart';
import 'package:tilomnov/features/home/utils/map/cluster_layout.dart';
import 'package:tilomnov/features/home/utils/map/map_overlay_builder.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';

PropertyModel _listing(String id, double lng) => PropertyModel(
  id: id,
  title: id,
  price: '1000',
  propertyType: 'Sell',
  status: 'Active',
  createdAt: DateTime(2020),
  lat: 11.55,
  lng: lng,
);

Future<ClusterLayout?> _layout(
  WidgetTester tester,
  double zoom, {
  PropertyModel? selected,
}) async {
  final overlays = await tester.runAsync(
    () => MapOverlayBuilder.buildListings(
      mapState: const MapState(),
      zoom: zoom,
      mapProperties: MapProperties(
        // ~1 km apart: ~58 px at zoom 13 (two dots), ~7 px at 10 (one bubble).
        properties: [_listing('a', 104.9200), _listing('b', 104.9300)],
      ),
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
  return overlays!.clusters;
}

void main() {
  testWidgets('zoomed out, merged listings share one bubble', (tester) async {
    final layout = (await _layout(tester, 10))!;

    expect(layout.zoomLevel, 10);
    expect(layout.spotOf['a'], same(layout.spotOf['b']));
    expect(layout.spotOf['a']!.count, 2);
    expect(layout.spotOf['a']!.markerId, startsWith('cluster_'));
  });

  testWidgets('closer in, each listing has its own dot', (tester) async {
    final layout = (await _layout(tester, 13))!;

    expect(layout.spotOf['a']!.markerId, 'dot_0');
    expect(layout.spotOf['b']!.markerId, 'dot_1');
  });

  testWidgets('the selected listing never takes part', (tester) async {
    final layout = (await _layout(tester, 10, selected: _listing('a', 0)))!;

    expect(layout.spotOf.keys, ['b']);
  });

  testWidgets('zoomed in, each listing is its own price tag', (tester) async {
    final layout = (await _layout(tester, 16))!;

    expect(layout.zoomLevel, 16);
    expect(layout.spotOf['a']!.markerId, 'city_dot_0');
    expect(layout.spotOf['a']!.tag, isNotNull);
    expect(layout.spotOf['b']!.tag, isNotNull);
  });

  testWidgets('zoomed in, the selected listing never takes part', (
    tester,
  ) async {
    final layout = (await _layout(tester, 16, selected: _listing('a', 0)))!;

    expect(layout.spotOf.keys, ['b']);
  });
}
