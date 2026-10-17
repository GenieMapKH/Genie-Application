import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

/// Answers each map search only when the test says so.
class _MapRepository extends PropertyRepository {
  final searches =
      <
        ({
          double minLat,
          String? propertyType,
          String? listingType,
          Completer<List<PropertyModel>> answer,
        })
      >[];

  _MapRepository() : super(Dio());

  @override
  Future<List<PropertyModel>> fetchPublicMapProperties({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    String? propertyType,
    String? listingType,
  }) {
    final answer = Completer<List<PropertyModel>>();
    searches.add((
      minLat: minLat,
      propertyType: propertyType,
      listingType: listingType,
      answer: answer,
    ));
    return answer.future;
  }
}

PropertyModel _listing(String id) => PropertyModel.fromJson({
  'id': id,
  'title': id,
  'price': '1',
  'propertyType': 'Land',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
  'images': <Object>[],
});

MapBounds _area(double lat) =>
    MapBounds(minLat: lat, maxLat: lat + 0.1, minLng: 104.8, maxLng: 104.9);

void main() {
  late _MapRepository repo;
  late ProviderContainer container;

  List<String> shownIds() => [
    for (final p in container.read(publicPropertiesProvider).value ?? []) p.id,
  ];

  setUp(() {
    repo = _MapRepository();
    container = ProviderContainer(
      overrides: [propertyRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(publicPropertiesProvider, (_, _) {});
  });

  test('asks for nothing until the map says what it shows', () async {
    await container.read(publicPropertiesProvider.future);

    expect(repo.searches, isEmpty);
    expect(shownIds(), isEmpty);
  });

  test(
    'moving the map replaces the listings instead of piling them up',
    () async {
      container.read(mapBoundsProvider.notifier).state = _area(11.5);
      repo.searches.last.answer.complete([_listing('old-area')]);
      await pumpEventQueue();
      expect(shownIds(), ['old-area']);

      container.read(mapBoundsProvider.notifier).state = _area(12.5);
      repo.searches.last.answer.complete([_listing('new-area')]);
      await pumpEventQueue();

      expect(shownIds(), ['new-area']);
    },
  );

  test('an answer that arrives after a newer search is dropped', () async {
    container.read(mapBoundsProvider.notifier).state = _area(11.5);
    container.read(mapBoundsProvider.notifier).state = _area(12.5);
    final [slow, fast] = repo.searches;

    fast.answer.complete([_listing('where-the-map-is')]);
    await pumpEventQueue();
    slow.answer.complete([_listing('where-it-was')]);
    await pumpEventQueue();

    expect(shownIds(), ['where-the-map-is']);
  });

  test('a failed search keeps the listings already shown', () async {
    container.read(mapBoundsProvider.notifier).state = _area(11.5);
    repo.searches.last.answer.complete([_listing('shown')]);
    await pumpEventQueue();

    container.read(mapBoundsProvider.notifier).state = _area(12.5);
    repo.searches.last.answer.completeError(Exception('offline'));
    await pumpEventQueue();

    expect(shownIds(), ['shown']);
  });

  test('a filter pill asks again for the same area, filtered', () async {
    container.read(mapBoundsProvider.notifier).state = _area(11.5);
    repo.searches.last.answer.complete([_listing('any')]);
    await pumpEventQueue();

    container.read(mapPropertyFilterProvider.notifier).state =
        const MapPropertyFilter(propertyType: 'House', listingType: 'Rent');
    await pumpEventQueue();

    final filtered = repo.searches.last;
    expect(repo.searches, hasLength(2));
    expect(filtered.minLat, 11.5);
    expect(filtered.propertyType, 'House');
    expect(filtered.listingType, 'Rent');
  });
}
