import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/notifications/models/push_message.dart';
import 'package:genie/features/property/data/models/map_property_filter.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/search/data/models/saved_search.dart';
import 'package:genie/features/search/data/saved_search_repository.dart';
import 'package:genie/features/search/presentation/screens/saved_searches_page.dart';
import 'package:genie/features/search/presentation/view_models/saved_searches_provider.dart';
import 'package:genie/features/search/presentation/widgets/saved/save_search_flow.dart';

import '../../support/test_app.dart';

const _area = MapBounds(
  minLat: 11.5,
  maxLat: 11.6,
  minLng: 104.85,
  maxLng: 104.95,
);

Map<String, Object?> _json({
  String id = 's1',
  String name = 'Toul Kork houses',
  bool alerts = true,
}) => {
  'id': id,
  'name': name,
  'minLat': 11.5,
  'maxLat': 11.6,
  'minLng': 104.85,
  'maxLng': 104.95,
  'propertyType': 'House',
  'listingTypes': ['Sale'],
  'minPrice': 50000,
  'maxPrice': 200000,
  'minSize': null,
  'maxSize': null,
  'keywords': ['near_school'],
  'alerts': alerts,
  'createdAt': '2026-10-24T00:00:00.000Z',
};

void main() {
  test('reads a saved search back into the map filter it was saved from', () {
    final search = SavedSearch.fromJson(_json());

    expect(search.area.minLng, 104.85);
    expect(search.filter.propertyType, 'House');
    expect(search.filter.isForSale, isTrue);
    expect(search.filter.minPrice, 50000);
    expect(search.filter.keywords, {'near_school'});
    expect(
      SavedSearch.requestBody(
        name: search.name,
        area: search.area,
        filter: search.filter,
      ),
      {
        'name': 'Toul Kork houses',
        'minLat': 11.5,
        'maxLat': 11.6,
        'minLng': 104.85,
        'maxLng': 104.95,
        'propertyType': 'House',
        'listingTypes': ['Sale'],
        'minPrice': 50000.0,
        'maxPrice': 200000.0,
        'keywords': ['near_school'],
      },
    );
  });

  test('an empty filter saves only the area and the name', () {
    expect(
      SavedSearch.requestBody(
        name: 'Here',
        area: _area,
        filter: const MapPropertyFilter(),
      ).keys,
      ['name', 'minLat', 'maxLat', 'minLng', 'maxLng'],
    );
  });

  test('says when the server holds as many as it keeps', () async {
    final repository = SavedSearchRepository(StubServer.always(409).dio);
    await expectLater(
      repository.save(
        name: 'x',
        area: _area,
        filter: const MapPropertyFilter(),
      ),
      throwsA(isA<SavedSearchLimitReached>()),
    );
  });

  test('a saved-search push opens its listing', () {
    final push = PushMessage.fromData({
      'type': 'saved_search_match',
      'propertyId': 'p-1',
    });
    expect(push, isA<ListingAlertPush>());
    expect((push as ListingAlertPush).propertyId, 'p-1');
    expect(
      PushMessage.fromData({'type': 'saved_search_match'}),
      isA<UnknownPush>(),
    );
  });

  group('the page', () {
    late StubServer server;
    late List<Map<String, Object?>> stored;

    Future<ProviderContainer> open(WidgetTester tester) async {
      stored = [_json(), _json(id: 's2', name: 'BKK1 condos', alerts: false)];
      server = StubServer((request) {
        if (request.method == 'GET') return (200, jsonEncode(stored));
        if (request.method == 'PATCH') {
          final body = request.data as Map<String, dynamic>;
          return (200, jsonEncode({..._json(), ...body}));
        }
        return (204, '');
      });
      await pumpTestApp(
        tester,
        const SavedSearchesPage(),
        overrides: [
          signedInOverride(),
          savedSearchRepositoryProvider.overrideWithValue(
            SavedSearchRepository(server.dio),
          ),
        ],
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(SavedSearchesPage)),
      );
    }

    testWidgets('lists each search with what it looks for', (tester) async {
      await open(tester);

      expect(find.text('Toul Kork houses'), findsOneWidget);
      expect(
        find.text('House · For sale · \$50K–\$200K · 1 keyword'),
        findsNWidgets(2),
      );
      expect(find.text('BKK1 condos'), findsOneWidget);
    });

    testWidgets('turns alerts off on the server', (tester) async {
      await open(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final patch = server.requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.path, '/search/saved/s1');
      expect(patch.body, {'alerts': false});
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    });

    testWidgets('deletes one', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(server.requests.last.method, 'DELETE');
      expect(server.requests.last.path, '/search/saved/s1');
      expect(find.text('Toul Kork houses'), findsNothing);
    });

    testWidgets('a tap asks the map to show it', (tester) async {
      final container = await open(tester);

      await tester.tap(find.text('BKK1 condos'));
      await tester.pump();

      expect(container.read(savedSearchToOpenProvider)?.id, 's2');
    });
  });

  testWidgets('saving names it after its filter and keeps the map area', (
    tester,
  ) async {
    final server = StubServer(
      (request) => request.method == 'GET'
          ? (200, '[]')
          : (201, jsonEncode(_json(name: 'Mine'))),
    );
    const filter = MapPropertyFilter(
      propertyType: 'House',
      listingTypes: MapPropertyFilter.forSale,
    );
    await pumpTestApp(
      tester,
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => saveMapSearch(context, ref, filter: filter),
          child: const Text('save'),
        ),
      ),
      overrides: [
        signedInOverride(),
        mapBoundsProvider.overrideWith((ref) => _area),
        savedSearchRepositoryProvider.overrideWithValue(
          SavedSearchRepository(server.dio),
        ),
      ],
    );

    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    expect(find.text('House · For sale'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Mine  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final post = server.requests.singleWhere((r) => r.method == 'POST');
    expect(post.body, {
      'name': 'Mine',
      'minLat': 11.5,
      'maxLat': 11.6,
      'minLng': 104.85,
      'maxLng': 104.95,
      'propertyType': 'House',
      'listingTypes': ['Sale'],
    });
    await tester.pump(const Duration(seconds: 5));
  });
}
