import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/presentation/providers/map_filter_draft_provider.dart';
import 'package:tilomnov/features/home/presentation/screens/map_filter_page.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/map_property_filter.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';

import '../../support/test_app.dart';

PropertyModel _listing({
  String listing = 'Sale',
  String price = '1000',
  String type = 'Land',
  double? landSize,
  double? unitSize,
  List<String> keywords = const [],
}) => PropertyModel.fromJson({
  'id': 'p',
  'title': 'p',
  'price': price,
  'propertyType': type,
  'listingType': listing,
  'landSize': landSize,
  'unitSize': unitSize,
  'keywords': [
    for (final k in keywords) {'keyword': k},
  ],
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
});

const _area = MapBounds(minLat: 11, maxLat: 12, minLng: 104, maxLng: 105);

void main() {
  group('MapPropertyFilter', () {
    test('keeps a price inside the range, ends included', () {
      const filter = MapPropertyFilter(minPrice: 1000, maxPrice: 2000);
      expect(filter.matches(_listing(price: '1000')), isTrue);
      expect(filter.matches(_listing(price: '2000')), isTrue);
      expect(filter.matches(_listing(price: '999')), isFalse);
      expect(filter.matches(_listing(price: '2001')), isFalse);
    });

    test('reads the size a card shows, and drops listings without one', () {
      const filter = MapPropertyFilter(minSize: 100);
      expect(filter.matches(_listing(landSize: 150)), isTrue);
      expect(filter.matches(_listing(type: 'Condo', unitSize: 150)), isTrue);
      // A condo is measured by its unit, not land it happens to carry.
      expect(
        filter.matches(_listing(type: 'Condo', landSize: 150, unitSize: 50)),
        isFalse,
      );
      expect(filter.matches(_listing(unitSize: 150)), isFalse);
      expect(filter.matches(_listing()), isFalse);
    });

    test('needs every chosen keyword', () {
      const filter = MapPropertyFilter(
        keywords: {'road_access', 'corner_land'},
      );
      expect(
        filter.matches(_listing(keywords: ['road_access', 'corner_land'])),
        isTrue,
      );
      expect(filter.matches(_listing(keywords: ['road_access'])), isFalse);
    });

    test('"For rent" takes Rent and To Let listings', () {
      const filter = MapPropertyFilter(listingTypes: MapPropertyFilter.forRent);
      expect(filter.isForRent, isTrue);
      expect(filter.matches(_listing(listing: 'To Let')), isTrue);
      expect(filter.matches(_listing(listing: 'Rent')), isTrue);
      expect(filter.matches(_listing(listing: 'Sale')), isFalse);
    });

    test('is the same filter whatever order its lists are in', () {
      expect(
        const MapPropertyFilter(listingTypes: ['Rent', 'To Let']),
        const MapPropertyFilter(listingTypes: ['To Let', 'Rent']),
      );
    });
  });

  group('the map request', () {
    late Uri asked;
    late PropertyRepository repo;

    setUp(() {
      repo = PropertyRepository(
        StubServer((request) {
          asked = request.uri;
          return request.uri.path.endsWith('/prices')
              ? (200, '{"counts":[1,0,2]}')
              : (200, '[]');
        }).dio,
      );
    });

    test('sends every part of the filter, lists as repeated keys', () async {
      await repo.fetchPublicMapProperties(
        minLat: 11,
        maxLat: 12,
        minLng: 104,
        maxLng: 105,
        filter: const MapPropertyFilter(
          listingTypes: MapPropertyFilter.forRent,
          minPrice: 100,
          maxSize: 500,
          keywords: {'water_supply', 'corner_land'},
        ),
      );

      expect(asked.path, '/public/properties/map');
      expect(asked.queryParametersAll['listingType'], ['Rent', 'To Let']);
      expect(asked.queryParametersAll['keyword'], [
        'corner_land',
        'water_supply',
      ]);
      expect(asked.queryParameters['minPrice'], '100.0');
      expect(asked.queryParameters['maxSize'], '500.0');
      expect(asked.queryParameters.containsKey('maxPrice'), isFalse);
    });

    test('asks for the histogram without the price range', () async {
      final counts = await repo.fetchMapPriceHistogram(
        minLat: 11,
        maxLat: 12,
        minLng: 104,
        maxLng: 105,
        filter: const MapPropertyFilter(minPrice: 5, propertyType: 'Land'),
        upTo: 500000,
      );

      expect(counts, [1, 0, 2]);
      expect(asked.path, '/public/properties/map/prices');
      expect(asked.queryParameters['propertyType'], 'Land');
      expect(asked.queryParameters.containsKey('minPrice'), isFalse);
      expect(asked.queryParameters['upTo'], '500000.0');
    });
  });

  group('the filter page draft', () {
    late ProviderContainer container;
    MapFilterDraftNotifier draft() =>
        container.read(mapFilterDraftProvider.notifier);

    setUp(() {
      container = ProviderContainer();
      container.listen(mapFilterDraftProvider, (_, _) {});
    });
    tearDown(() => container.dispose());

    test('starts from what the map shows, and leaves it until applied', () {
      container.dispose();
      container = ProviderContainer();
      container.read(mapPropertyFilterProvider.notifier).state =
          const MapPropertyFilter(propertyType: 'House');
      container.listen(mapFilterDraftProvider, (_, _) {});

      draft().toggleKeyword('road_access');
      expect(container.read(mapFilterDraftProvider).propertyType, 'House');
      expect(container.read(mapPropertyFilterProvider).keywords, isEmpty);

      expect(draft().apply(), isTrue);
      expect(container.read(mapPropertyFilterProvider).keywords, {
        'road_access',
      });
    });

    test('switching sale and rent starts the price over', () {
      draft().selectListing(MapPropertyFilter.forSale);
      draft().setPrice(10000, 20000);
      draft().selectListing(MapPropertyFilter.forRent);

      final filter = container.read(mapFilterDraftProvider);
      expect(filter.isForRent, isTrue);
      expect(filter.minPrice, isNull);
      expect(MapPriceScale.of(filter), MapPriceScale.rent);
    });

    test('reset keeps only the tab', () {
      draft().selectListing(MapPropertyFilter.forRent);
      draft().setSize(10, 20);
      draft().toggleType('Condo');
      draft().reset();

      expect(
        container.read(mapFilterDraftProvider),
        const MapPropertyFilter(listingTypes: MapPropertyFilter.forRent),
      );
    });

    test('refuses an upside-down range', () {
      draft().setSize(500, 100);
      expect(draft().apply(), isFalse);
      expect(container.read(mapPropertyFilterProvider).isEmpty, isTrue);
    });

    test('starts on "For sale" when the map takes any listing type', () {
      expect(container.read(mapFilterDraftProvider).isForSale, isTrue);
    });

    test('keeps the listing type the map already has', () {
      container.dispose();
      container = ProviderContainer();
      container.read(mapPropertyFilterProvider.notifier).state =
          const MapPropertyFilter(listingTypes: MapPropertyFilter.forRent);
      container.listen(mapFilterDraftProvider, (_, _) {});

      expect(container.read(mapFilterDraftProvider).isForRent, isTrue);
    });
  });

  testWidgets('choosing on the page and tapping See results filters the map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    late ProviderContainer container;
    await pumpTestApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MapFilterPage()),
              ),
              child: const Text('open'),
            ),
          );
        },
      ),
      overrides: [
        propertyRepositoryProvider.overrideWithValue(
          PropertyRepository(
            StubServer((_) => (200, '{"counts":[3,1,2]}')).dio,
          ),
        ),
      ],
    );
    container.read(mapBoundsProvider.notifier).state = _area;

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Down payment'), findsOneWidget);

    await tester.tap(find.text('For rent'));
    await tester.pumpAndSettle();
    // Rent is paid monthly, and has no down payment.
    expect(find.text(r'$5K+/month'), findsOneWidget);
    expect(find.text('Down payment'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '300');
    await tester.scrollUntilVisible(
      find.text('Corner Land'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Corner Land'));
    await tester.pump();

    await tester.tap(find.text('See results'));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsNothing);
    expect(
      container.read(mapPropertyFilterProvider),
      const MapPropertyFilter(
        listingTypes: MapPropertyFilter.forRent,
        minPrice: 300,
        keywords: {'corner_land'},
      ),
    );
  });
}
