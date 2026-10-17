import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:genie/features/search/data/search_failure.dart';
import 'package:genie/features/search/data/search_repository.dart';
import 'package:genie/features/search/presentation/view_models/search_providers.dart';
import 'package:genie/features/search/presentation/view_models/search_query_controller.dart';

import '../../support/test_app.dart';

const _answer = '''
{"places": [{"placeId": "ChIJveng-sreng", "primaryText": "Veng Sreng Blvd", "secondaryText": "Phnom Penh"}],
 "properties": [],
 "people": [{"id": "u-1", "name": "Sokha Realty", "username": "sokha", "avatarUrl": null, "listingCount": 2}]}
''';

/// Timers only advance with `tester.pump`, so these run inside testWidgets.
void main() {
  late StubServer server;
  late ProviderContainer container;
  late ProviderSubscription<SearchQueryState> subscription;
  late List<Map<String, dynamic>> queries;

  SearchQueryController controller() =>
      container.read(searchQueryControllerProvider.notifier);
  SearchQueryState state() => subscription.read();
  void start(WidgetTester tester, {int status = 200, String body = _answer}) {
    queries = [];
    server = StubServer((request) {
      queries.add(request.queryParameters);
      return (status, body);
    });
    container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(
          SearchRepository(server.dio),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Keeps the auto-disposed controller alive, as the open page does.
    subscription = container.listen(searchQueryControllerProvider, (_, _) {});
    controller().configure(language: 'en');
  }

  testWidgets('waits for a pause in typing, then asks once', (tester) async {
    start(tester);

    for (final text in ['v', 've', 'ven', 'Veng', 'Veng ', 'Veng S']) {
      controller().onTextChanged(text);
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(server.requests, isEmpty);
    expect(state().isLoading, isTrue);

    await tester.pump(SearchQueryController.debounce);
    await tester.pump();

    expect(server.requests.single.path, '/public/search');
    expect(queries.single['q'], 'veng s');
    expect(state().isLoading, isFalse);
    expect(state().text, 'veng s');
    expect(state().results.places.single.primaryText, 'Veng Sreng Blvd');
    expect(state().results.people.single.displayName, 'Sokha Realty');
  });

  testWidgets('never asks for a text shorter than two characters', (
    tester,
  ) async {
    start(tester);

    controller().onTextChanged('v');
    await tester.pump(const Duration(seconds: 1));

    expect(server.requests, isEmpty);
    expect(state().isIdle, isTrue);
  });

  testWidgets('answers a text seen before from memory', (tester) async {
    start(tester);

    controller().onTextChanged('veng');
    await tester.pump(const Duration(seconds: 1));
    controller().onTextChanged('vengs');
    await tester.pump(const Duration(seconds: 1));
    expect(server.requests, hasLength(2));

    // Deleting the last letter, and different case or spacing, cost nothing.
    controller().onTextChanged('veng');
    controller().onTextChanged(' VENG ');
    await tester.pump(const Duration(seconds: 1));

    expect(server.requests, hasLength(2));
    expect(state().text, 'veng');
    expect(state().isLoading, isFalse);
    expect(state().results.places, isNotEmpty);
  });

  testWidgets('the search key asks at once, without the pause', (tester) async {
    start(tester);

    controller().onTextChanged('veng');
    controller().submit('veng');
    // Far shorter than the pause: Dio's own pipeline only needs a moment.
    await tester.pump(const Duration(milliseconds: 50));

    expect(server.requests, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    expect(server.requests, hasLength(1), reason: 'the pending pause is void');
  });

  testWidgets('explains a refusal, and retries on demand', (tester) async {
    start(tester, status: 429, body: '{"statusCode": 429}');

    controller().onTextChanged('veng');
    await tester.pump(const Duration(seconds: 1));

    expect(state().failure, SearchFailureReason.tooManyRequests);
    expect(state().isLoading, isFalse);

    controller().retry();
    await tester.pump(const Duration(milliseconds: 50));
    expect(server.requests, hasLength(2));
  });

  testWidgets('sends the language, the session and the map position', (
    tester,
  ) async {
    start(tester);
    controller().configure(
      language: 'km',
      near: const LatLng(11.556412, 104.928209),
    );

    controller().submit('veng');
    await tester.pump(const Duration(milliseconds: 50));

    expect(queries.single, {
      'q': 'veng',
      'lang': 'km',
      'session': controller().sessionToken,
      'lat': '11.5564',
      'lng': '104.9282',
    });
  });
}
