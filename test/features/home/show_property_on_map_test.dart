import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/map_properties_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/show_property_on_map.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';

PropertyModel _property({double? lat, double? lng}) => PropertyModel(
  id: 'p1',
  title: 'Plot',
  price: '100000',
  propertyType: 'Land',
  status: 'Active',
  createdAt: DateTime(2026, 1, 1),
  lat: lat,
  lng: lng,
);

void main() {
  test('only listings with a place can be shown on the map', () {
    expect(canShowPropertyOnMap(_property(lat: 11.5, lng: 104.9)), isTrue);
    expect(canShowPropertyOnMap(_property()), isFalse);
  });

  testWidgets('closes pages, returns to Explore and selects the listing', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        mapPropertiesProvider.overrideWithValue(
          const MapProperties(properties: []),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(mainNavProvider.notifier).setIndex(MainTab.saved);
    final property = _property(lat: 11.5, lng: 104.9);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const Text('home'),
          builder: (context, child) => child!,
        ),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => showPropertyOnMap(context, ref, property),
            child: const Text('map'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('map'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(container.read(mainNavProvider).currentIndex, MainTab.explore);
    expect(container.read(propertyCarouselProvider).selected?.id, 'p1');
  });
}
