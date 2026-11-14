import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/search/home_search_bar.dart';
import 'package:tilomnov/features/search/data/search_history_repository.dart';
import 'package:tilomnov/features/search/data/search_repository.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_area_controller.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_providers.dart';
import 'package:tilomnov/features/search/presentation/widgets/results/place_result_tile.dart';

import '../../support/test_app.dart';

Future<void> _finishTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Future<void> _loadResults(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await _finishTransition(tester);
}

void main() {
  testWidgets('selected place can be reopened, edited, replaced and cleared', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.reset);

    final queries = <String>[];
    final server = StubServer((request) {
      if (request.path == '/public/search') {
        final query = request.queryParameters['q'] as String;
        queries.add(query);
        final title = query == 'toul kork' ? 'Toul Kork' : 'Chom Chau 1';
        return (
          200,
          jsonEncode({
            'places': [
              {'placeId': title, 'primaryText': title, 'secondaryText': ''},
            ],
            'properties': [],
            'people': [],
          }),
        );
      }
      return (
        200,
        '{"place":{"viewport":{"minLat":11.5,"maxLat":11.6,'
            '"minLng":104.8,"maxLng":104.9}},"properties":[]}',
      );
    });

    await pumpTestApp(
      tester,
      Scaffold(
        body: SafeArea(
          child: HomeSearchBar(
            onOpenProperty: (_) => fail('A place must not open a listing'),
          ),
        ),
      ),
      overrides: [
        glassNavigationOnProvider.overrideWithValue(false),
        searchRepositoryProvider.overrideWithValue(
          SearchRepository(server.dio),
        ),
        searchHistoryRepositoryProvider.overrideWithValue(
          SearchHistoryRepository(server.dio),
        ),
        searchHasSessionProvider.overrideWithValue(() async => false),
      ],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeSearchBar)),
    );

    await tester.tap(find.byType(HomeSearchBar));
    await _finishTransition(tester);
    await tester.enterText(find.byType(TextField), 'chom chau');
    await _loadResults(tester);
    await tester.tap(find.byType(PlaceResultTile));
    await _finishTransition(tester);
    expect(
      container.read(searchAreaControllerProvider)!.target.title,
      'Chom Chau 1',
    );
    expect(container.read(searchAreaControllerProvider)!.area.hasValue, isTrue);

    // Reopen first without a cached title query, then with one.
    for (var visit = 0; visit < 2; visit++) {
      await tester.tap(find.byType(HomeSearchBar));
      await _finishTransition(tester);
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.controller!.text, 'Chom Chau 1');
      expect(
        input.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 11),
      );
      await _loadResults(tester);
      expect(
        find.descendant(
          of: find.byType(PlaceResultTile),
          matching: find.text('Chom Chau 1'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (visit == 0) {
        await tester.tap(find.byTooltip('Back'));
        await _finishTransition(tester);
      }
    }
    expect(queries, ['chom chau', 'chom chau 1']);

    await tester.enterText(find.byType(TextField), 'toul kork');
    await _loadResults(tester);
    await tester.tap(find.byType(PlaceResultTile));
    await _finishTransition(tester);
    expect(
      container.read(searchAreaControllerProvider)!.target.title,
      'Toul Kork',
    );

    await tester.tap(find.byTooltip('Clear search'));
    await _finishTransition(tester);
    expect(container.read(searchAreaControllerProvider), isNull);
    await tester.tap(find.byType(HomeSearchBar));
    await _finishTransition(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
