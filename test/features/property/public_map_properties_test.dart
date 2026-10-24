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
          double maxLat,
          MapPropertyFilter filter,
          Completer<List<PropertyModel>> answer,
          CancelToken? cancelToken,
        })
      >[];

  _MapRepository() : super(Dio());

  @override
  Future<List<PropertyModel>> fetchPublicMapProperties({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    MapPropertyFilter filter = const MapPropertyFilter(),
    CancelToken? cancelToken,
  }) {
    final answer = Completer<List<PropertyModel>>();
    searches.add((
      minLat: minLat,
      maxLat: maxLat,
      filter: filter,
      answer: answer,
      cancelToken: cancelToken,
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

    container
        .read(mapPropertyFilterProvider.notifier)
        .state = const MapPropertyFilter(
      propertyType: 'House',
      listingTypes: ['Rent'],
      minPrice: 100,
    );
    await pumpEventQueue();

    final filtered = repo.searches.last;
    expect(repo.searches, hasLength(2));
    expect(filtered.minLat, 11.5);
    expect(filtered.filter.propertyType, 'House');
    expect(filtered.filter.listingTypes, ['Rent']);
    expect(filtered.filter.minPrice, 100);
  });

  test('a newer search gives up the one still on its way', () async {
    container.read(mapBoundsProvider.notifier).state = _area(11.5);
    container.read(mapBoundsProvider.notifier).state = _area(12.5);
    final [slow, fast] = repo.searches;

    expect(slow.cancelToken!.isCancelled, isTrue);
    expect(fast.cancelToken!.isCancelled, isFalse);

    // Being given up is not a failure: what the newer search finds is shown.
    slow.answer.completeError(
      DioException.requestCancelled(
        requestOptions: RequestOptions(),
        reason: 'newer search',
      ),
    );
    fast.answer.complete([_listing('where-the-map-is')]);
    await pumpEventQueue();
    expect(shownIds(), ['where-the-map-is']);
  });

  test("asks for the area widened to the server's grid", () async {
    container.read(mapBoundsProvider.notifier).state = const MapBounds(
      minLat: 11.5512,
      maxLat: 11.5688,
      minLng: 104.9101,
      maxLng: 104.9299,
    );

    expect(repo.searches.single.minLat, 11.55);
    expect(repo.searches.single.maxLat, 11.57);
  });

  group('widened to the grid', () {
    test('a box already on the grid stays exactly as it is', () {
      for (var step = -9000; step <= 9000; step++) {
        final degrees = step / 100;
        final box = MapBounds(
          minLat: degrees,
          maxLat: degrees,
          minLng: degrees * 2,
          maxLng: degrees * 2,
        ).widenedToGrid();
        expect([box.minLat, box.maxLat], [degrees, degrees]);
        expect([box.minLng, box.maxLng], [degrees * 2, degrees * 2]);
      }
    });

    test('never smaller than the view, and never past the poles', () {
      const view = MapBounds(
        minLat: -89.999,
        maxLat: 89.999,
        minLng: -179.9991,
        maxLng: 179.9991,
      );
      final box = view.widenedToGrid();

      expect(box.minLat, -90);
      expect(box.maxLat, 90);
      expect(box.minLng, -180);
      expect(box.maxLng, 180);
    });
  });
}
