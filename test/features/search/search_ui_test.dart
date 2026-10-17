import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/features/search/data/search_repository.dart';
import 'package:genie/features/search/presentation/screens/search_page.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/search/presentation/view_models/search_providers.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';
import 'package:genie/features/search/presentation/widgets/area/search_area_panel.dart';

import '../../support/test_app.dart';

const _listing = '''
{"id": "p-1", "title": "Land near Veng Sreng", "price": "120000", "propertyType": "Land",
 "status": "Active", "createdAt": "2026-10-01T00:00:00.000Z", "lat": 11.52, "lng": 104.87,
 "images": [], "user": {"id": "u-1", "name": "Sokha Realty", "username": "sokha"}}
''';

const _results =
    '''
{"places": [{"placeId": "ChIJveng-sreng", "primaryText": "Veng Sreng Blvd", "secondaryText": "Phnom Penh"}],
 "properties": [$_listing],
 "people": [{"id": "u-1", "name": "Sokha Realty", "username": "sokha", "avatarUrl": null, "listingCount": 2}]}
''';

const _phone = Size(360, 740);
const _smallPhone = Size(320, 568);
const _tablet = Size(1024, 1366);

void _useScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<Override> _api(String body) => [
  searchRepositoryProvider.overrideWithValue(
    SearchRepository(StubServer.always(200, body).dio),
  ),
];

/// Opens the search page from a host page and returns what it closed with.
Future<SearchSelection? Function()> _openSearch(
  WidgetTester tester, {
  String body = _results,
}) async {
  SearchSelection? picked;
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async =>
              picked = await Navigator.of(context).push(SearchPage.route()),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: _api(body),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => picked;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size) in [
    ('small phone', _smallPhone),
    ('phone', _phone),
    ('tablet', _tablet),
  ]) {
    testWidgets('shows places, listings and people on a $name', (tester) async {
      _useScreen(tester, size);
      await _openSearch(tester);

      expect(find.text('Find a place, a listing or a person'), findsOneWidget);
      await _type(tester, 'veng');

      expect(find.text('PLACES'), findsOneWidget);
      expect(find.text('LISTINGS'), findsOneWidget);
      expect(find.text('PEOPLE & AGENCIES'), findsOneWidget);
      expect(find.textContaining('Veng Sreng Blvd'), findsOneWidget);
      expect(find.textContaining('Sokha Realty'), findsOneWidget);
    });
  }

  testWidgets('picking a place hands back the place and its search session', (
    tester,
  ) async {
    _useScreen(tester, _phone);
    final picked = await _openSearch(tester);
    await _type(tester, 'veng');

    await tester.tap(find.textContaining('Veng Sreng Blvd'));
    await tester.pumpAndSettle();

    final selection = picked() as AreaSelection;
    final target = selection.target as PlaceTarget;
    expect(target.place.placeId, 'ChIJveng-sreng');
    expect(target.sessionToken, isNotEmpty);
    expect(target.language, 'en');
  });

  testWidgets('the search key goes to the top place', (tester) async {
    _useScreen(tester, _phone);
    final picked = await _openSearch(tester);
    await _type(tester, 'veng');

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(picked(), isA<AreaSelection>());
  });

  testWidgets('picking a listing hands back that listing', (tester) async {
    _useScreen(tester, _phone);
    final picked = await _openSearch(tester);
    await _type(tester, 'veng');

    await tester.tap(find.text('\$ 120,000'));
    await tester.pumpAndSettle();

    expect((picked() as PropertySelection).property.id, 'p-1');
  });

  testWidgets('says so when nothing matches', (tester) async {
    _useScreen(tester, _phone);
    await _openSearch(
      tester,
      body: '{"places": [], "properties": [], "people": []}',
    );
    await _type(tester, 'zzzz');

    expect(find.text('No results for “zzzz”'), findsOneWidget);
  });

  group('results panel on the map', () {
    final person = PublisherSummary(
      id: 'u-1',
      name: 'Sokha Realty',
      username: 'sokha',
      listingCount: 1,
    );
    final opened = <PropertyModel>[];

    Future<ProviderContainer> showPanel(WidgetTester tester) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.green)),
              SearchAreaPanel(
                margin: const EdgeInsets.only(left: 16, top: 140, bottom: 90),
                onOpenProperty: opened.add,
              ),
            ],
          ),
        ),
        overrides: _api(
          '{"person": {"id": "u-1", "name": "Sokha Realty", "listingCount": 1}, "properties": [$_listing]}',
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchAreaPanel)),
      );
      container
          .read(searchAreaControllerProvider.notifier)
          .show(PersonTarget(person));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('is a draggable sheet on phones', (tester) async {
      _useScreen(tester, _smallPhone);
      await showPanel(tester);

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('Sokha Realty'), findsOneWidget);
      expect(find.text('1 published listing'), findsOneWidget);

      await tester.tap(find.text('Land near Veng Sreng'));
      expect(opened.last.id, 'p-1');
    });

    testWidgets('is a side panel on tablets, and closes', (tester) async {
      _useScreen(tester, _tablet);
      final container = await showPanel(tester);

      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.text('Land near Veng Sreng'), findsOneWidget);

      await tester.tap(find.byTooltip('Close search results'));
      await tester.pumpAndSettle();
      expect(container.read(searchAreaControllerProvider), isNull);
      expect(find.text('Sokha Realty'), findsNothing);
    });
  });
}
