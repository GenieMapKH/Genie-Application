import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/home/presentation/providers/property_carousel_provider.dart';
import 'package:genie/features/property/data/models/property_model.dart';

PropertyModel _property(
  String id, {
  double? lat,
  double? lng,
  List<LatLng> boundary = const [],
}) {
  return PropertyModel(
    id: id,
    title: 'Property $id',
    price: '100000',
    propertyType: 'Land',
    status: 'Active',
    createdAt: DateTime(2026, 1, 1),
    lat: lat,
    lng: lng,
    boundaryPoints: boundary,
  );
}

/// Builds a container whose map feed is fixed to [properties].
ProviderContainer _containerWith(List<PropertyModel> properties) {
  final container = ProviderContainer(
    overrides: [
      mapPropertiesProvider.overrideWithValue(
        MapProperties(properties: properties),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('PropertyCarouselNotifier.centerOf', () {
    test('returns the centroid for a property with a boundary', () {
      final property = _property(
        'a',
        boundary: const [
          LatLng(0, 0),
          LatLng(0, 2),
          LatLng(2, 2),
          LatLng(2, 0),
        ],
      );

      final center = PropertyCarouselNotifier.centerOf(property);

      expect(center!.latitude, closeTo(1.0, 1e-9));
      expect(center.longitude, closeTo(1.0, 1e-9));
    });

    test('falls back to the pin when there is no boundary', () {
      final center =
          PropertyCarouselNotifier.centerOf(_property('a', lat: 11.5, lng: 104.9));

      expect(center, const LatLng(11.5, 104.9));
    });

    test('returns null when the property has no location at all', () {
      expect(PropertyCarouselNotifier.centerOf(_property('a')), isNull);
    });
  });

  group('select', () {
    test('puts the tapped property first and sorts the rest by distance', () {
      final anchor = _property('anchor', lat: 11.50, lng: 104.90);
      final near = _property('near', lat: 11.51, lng: 104.90);
      final far = _property('far', lat: 11.90, lng: 104.90);
      final mid = _property('mid', lat: 11.60, lng: 104.90);

      final container = _containerWith([far, mid, near, anchor]);
      container.read(propertyCarouselProvider.notifier).select(anchor);

      final state = container.read(propertyCarouselProvider);
      expect(
        state.items.map((p) => p.id),
        ['anchor', 'near', 'mid', 'far'],
      );
      expect(state.index, 0);
      expect(state.selected?.id, 'anchor');
      expect(state.isVisible, isTrue);
    });

    test('excludes properties that have no location', () {
      final anchor = _property('anchor', lat: 11.5, lng: 104.9);
      final located = _property('located', lat: 11.6, lng: 104.9);
      final unlocated = _property('unlocated');

      final container = _containerWith([anchor, located, unlocated]);
      container.read(propertyCarouselProvider.notifier).select(anchor);

      expect(
        container.read(propertyCarouselProvider).items.map((p) => p.id),
        ['anchor', 'located'],
      );
    });

    test('moves the index without rebuilding when already in the list', () {
      final anchor = _property('anchor', lat: 11.5, lng: 104.9);
      final other = _property('other', lat: 11.6, lng: 104.9);

      final container = _containerWith([anchor, other]);
      final notifier = container.read(propertyCarouselProvider.notifier);

      notifier.select(anchor);
      final firstList = container.read(propertyCarouselProvider).items;

      notifier.select(other);
      final state = container.read(propertyCarouselProvider);

      expect(state.index, 1);
      expect(state.selected?.id, 'other');
      // Same list instance: swiping must not reshuffle the cards.
      expect(state.items, same(firstList));
    });

    test('rebuilds the list when selecting a property outside it', () {
      final anchor = _property('anchor', lat: 11.5, lng: 104.9);
      final other = _property('other', lat: 11.6, lng: 104.9);
      final outsider = _property('outsider', lat: 20.0, lng: 100.0);

      // Only the first two are on the map, so `outsider` can't be in the list.
      final container = _containerWith([anchor, other]);
      final notifier = container.read(propertyCarouselProvider.notifier);

      notifier.select(anchor);
      notifier.select(outsider);

      final state = container.read(propertyCarouselProvider);
      expect(state.index, 0);
      expect(state.items.first.id, 'outsider');
    });
  });

  group('setIndex', () {
    test('ignores out-of-range indices', () {
      final anchor = _property('anchor', lat: 11.5, lng: 104.9);
      final container = _containerWith([anchor]);
      final notifier = container.read(propertyCarouselProvider.notifier);

      notifier.select(anchor);
      notifier.setIndex(5);
      notifier.setIndex(-1);

      expect(container.read(propertyCarouselProvider).index, 0);
    });
  });

  group('clear', () {
    test('hides the carousel', () {
      final anchor = _property('anchor', lat: 11.5, lng: 104.9);
      final container = _containerWith([anchor]);
      final notifier = container.read(propertyCarouselProvider.notifier);

      notifier.select(anchor);
      notifier.clear();

      final state = container.read(propertyCarouselProvider);
      expect(state.isVisible, isFalse);
      expect(state.selected, isNull);
    });
  });
}
