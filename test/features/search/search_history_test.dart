import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/search/data/search_history_repository.dart';
import 'package:tilomnov/features/search/data/search_repository.dart';
import 'package:tilomnov/features/search/presentation/screens/search_page.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_history_controller.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_providers.dart';

import '../../support/test_app.dart';

const _history = '''
[{"id": "11111111-1111-4111-8111-111111111111", "query": "Veng Sreng", "searchedAt": "2026-10-16T10:00:00.000Z"},
 {"id": "22222222-2222-4222-8222-222222222222", "query": "pou senchey", "searchedAt": "2026-10-15T10:00:00.000Z"}]
''';

const _results = '''
{"places": [{"placeId": "ChIJveng-sreng", "primaryText": "Veng Sreng Blvd", "secondaryText": "Phnom Penh"}],
 "properties": [], "people": []}
''';

/// The search API and the history API in one, recording what was asked.
class _Api {
  int deleteStatus = 204;
  final List<String> searchedTexts = [];
  final List<Object?> recorded = [];
  final List<String> deleted = [];

  late final StubServer server = StubServer((request) {
    switch ((request.method, request.path)) {
      case ('GET', '/search/history'):
        return (200, _history);
      case ('POST', '/search/history'):
        recorded.add(request.data);
        final query = (request.data as Map)['query'];
        return (
          201,
          '{"id": "33333333-3333-4333-8333-333333333333", "query": "$query", '
              '"searchedAt": "2026-10-16T12:00:00.000Z"}',
        );
      case ('DELETE', final path) when path.startsWith('/search/history/'):
        deleted.add(path.split('/').last);
        return (deleteStatus, '');
      case ('GET', '/public/search'):
        searchedTexts.add(request.queryParameters['q'] as String);
        return (200, _results);
    }
    return (404, '{}');
  });

  List<Override> overrides({bool signedIn = true}) => [
    searchRepositoryProvider.overrideWithValue(SearchRepository(server.dio)),
    searchHistoryRepositoryProvider.overrideWithValue(
      SearchHistoryRepository(server.dio),
    ),
    searchHasSessionProvider.overrideWithValue(() async => signedIn),
  ];
}

Future<void> _openSearch(
  WidgetTester tester,
  _Api api, {
  bool signedIn = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await pumpTestApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(SearchPage.route()),
          child: const Text('open'),
        ),
      ),
    ),
    overrides: api.overrides(signedIn: signedIn),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('shows the account\'s recent searches before anything is typed', (
    tester,
  ) async {
    await _openSearch(tester, _Api());

    expect(find.text('RECENT SEARCHES'), findsOneWidget);
    expect(find.text('Veng Sreng'), findsOneWidget);
    expect(find.text('pou senchey'), findsOneWidget);
  });

  testWidgets('a guest has no history', (tester) async {
    final api = _Api();
    await _openSearch(tester, api, signedIn: false);

    expect(find.text('RECENT SEARCHES'), findsNothing);
    expect(find.text('Find a place, a listing or a person'), findsOneWidget);
    expect(api.server.requests, isEmpty);
  });

  testWidgets('tapping a recent search runs it again at once', (tester) async {
    final api = _Api();
    await _openSearch(tester, api);

    await tester.tap(find.text('Veng Sreng'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(_fieldText(tester), 'Veng Sreng');
    expect(api.searchedTexts, ['veng sreng']);
    expect(find.textContaining('Veng Sreng Blvd'), findsOneWidget);
  });

  testWidgets('edit puts the search in the field to change it', (tester) async {
    final api = _Api();
    await _openSearch(tester, api);

    await tester.tap(find.byTooltip('Edit this search').last);
    await tester.pump();

    expect(_fieldText(tester), 'pou senchey');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.selection.baseOffset, 'pou senchey'.length);
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('remove forgets the search on the server', (tester) async {
    final api = _Api();
    await _openSearch(tester, api);

    await tester.tap(find.byTooltip('Remove from history').first);
    await tester.pumpAndSettle();

    expect(find.text('Veng Sreng'), findsNothing);
    expect(find.text('pou senchey'), findsOneWidget);
    expect(api.deleted, ['11111111-1111-4111-8111-111111111111']);
  });

  testWidgets('a refused removal puts the search back and says so', (
    tester,
  ) async {
    final api = _Api()..deleteStatus = 500;
    await _openSearch(tester, api);

    await tester.tap(find.byTooltip('Remove from history').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Veng Sreng'), findsOneWidget);
    expect(
      find.text('This search could not be removed. Please try again.'),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('picking a result saves what was typed', (tester) async {
    final api = _Api();
    await _openSearch(tester, api);

    await tester.enterText(find.byType(TextField), 'Veng sr');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Veng Sreng Blvd'));
    await tester.pumpAndSettle();

    expect(api.recorded, [
      {'query': 'Veng sr'},
    ]);
  });

  testWidgets('typing alone saves nothing', (tester) async {
    final api = _Api();
    await _openSearch(tester, api);

    await tester.enterText(find.byType(TextField), 'Veng sr');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(api.recorded, isEmpty);
  });

  test('a search again moves to the top instead of repeating', () async {
    final api = _Api();
    final container = ProviderContainer(overrides: api.overrides());
    addTearDown(container.dispose);
    final subscription = container.listen(
      searchHistoryControllerProvider,
      (_, _) {},
    );
    await container.read(searchHistoryControllerProvider.future);

    await container
        .read(searchHistoryControllerProvider.notifier)
        .record('  POU   senchey ');

    final entries = subscription.read().value!;
    expect(entries.map((e) => e.query), ['POU   senchey', 'Veng Sreng']);
  });
}
