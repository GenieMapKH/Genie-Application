import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';
import 'package:tilomnov/features/feed/data/feed_repository.dart';
import 'package:tilomnov/features/feed/presentation/screens/feed_page.dart';
import 'package:tilomnov/features/feed/presentation/view_models/feed_provider.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_listing_card.dart';
import 'package:tilomnov/features/follow/presentation/view_models/follow_providers.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/main_bottom_nav.dart';
import 'package:tilomnov/features/property/data/repositories/favorites_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:tilomnov/features/search/data/search_repository.dart';
import 'package:tilomnov/features/search/presentation/screens/publisher_profile_page.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_providers.dart';
import 'package:tilomnov/shared/transitions/circular_reveal_route.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_app.dart';

String _listing(String id, String title, {String owner = 'Sokha Realty'}) =>
    '{"id": "$id", "title": "$title", "price": "120000", '
    '"propertyType": "Land", "status": "Active", '
    '"createdAt": "2026-07-01T00:00:00.000Z", '
    '"publishedAt": "2026-10-15T00:00:00.000Z", "lat": 11.52, "lng": 104.87, '
    '"images": [], "user": {"id": "owner-$id", "name": "$owner"}}';

String _page(List<String> items, {String? next}) =>
    '{"items": [${items.join(', ')}], '
    '"nextCursor": ${next == null ? 'null' : '"$next"'}}';

/// The feed and the saved hearts, from one stub API. [feed] gets the cursor
/// asked for (null for the first page) and answers a page, or 'fail'.
StubServer _api(String Function(String? cursor) feed) {
  return StubServer((request) {
    if (request.path == '/properties/my/favorites/ids') return (200, '[]');
    // Dara's profile, which also shows the listing of theirs in the feed.
    if (request.path == '/public/search/people/owner-p-2') {
      return (
        200,
        '{"person": {"id": "owner-p-2", "name": "Dara", "listingCount": 1}, '
            '"properties": [${_listing('p-2', 'Shophouse Corner')}]}',
      );
    }
    if (request.path == '/feed') {
      final answer = feed(request.queryParameters['cursor'] as String?);
      return answer == 'fail' ? (500, '{}') : (200, answer);
    }
    return (404, '{}');
  });
}

/// The account signed in on the device during these tests.
const _me = 'user-me';
const _keptKey = 'feed.first_page.v1.$_me';

/// A clock the test moves.
class _Clock {
  DateTime now = DateTime(2026, 10, 21, 9);
  DateTime call() => now;
}

Future<ProviderContainer> _pumpFeed(
  WidgetTester tester,
  StubServer server, {
  bool signedIn = true,
  Map<String, Object> kept = const {},
  _Clock? clock,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await pumpTestApp(
    tester,
    const FeedPage(),
    savedSettings: kept,
    overrides: [
      feedRepositoryProvider.overrideWithValue(
        FeedRepository(server.dio, accountId: () async => _me),
      ),
      favoritesRepositoryProvider.overrideWithValue(
        FavoritesRepository(server.dio),
      ),
      searchRepositoryProvider.overrideWithValue(SearchRepository(server.dio)),
      if (clock != null) feedClockProvider.overrideWithValue(clock.call),
      signedInOverride(signedIn: signedIn),
    ],
  );
  await _settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(FeedPage)));
}

/// Lets the listings be parsed (`compute` runs on real time, not the
/// test's fake clock), then draws what came of it.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

List<ReceivedRequest> _feedRequests(StubServer server) =>
    server.requests.where((r) => r.path == '/feed').toList();

void main() {
  testWidgets('shows followed listings with who posted them and when', (
    tester,
  ) async {
    await _pumpFeed(
      tester,
      _api(
        (_) => _page([
          _listing('p-1', 'Land near Veng Sreng'),
          _listing('p-2', 'Shophouse Corner', owner: 'Dara'),
        ]),
      ),
    );

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Sokha Realty'), findsOneWidget);
    expect(find.text('Land near Veng Sreng'), findsOneWidget);
    // When it went live, not when its draft was started.
    expect(find.text('Listed Oct 15, 2026'), findsWidgets);
    expect(find.textContaining('Jul 1'), findsNothing);
    await tester.scrollUntilVisible(find.text('Dara'), 200);
    expect(find.text('Shophouse Corner'), findsOneWidget);
  });

  testWidgets('a profile opens out of the avatar and closes back into it', (
    tester,
  ) async {
    await _pumpFeed(
      tester,
      _api(
        (_) => _page([
          _listing('p-1', 'Land near Veng Sreng'),
          _listing('p-2', 'Shophouse Corner', owner: 'Dara'),
        ]),
      ),
    );
    await tester.scrollUntilVisible(find.text('Dara'), 200);
    final avatar = tester.getRect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Dara'),
          matching: find.byType(FeedListingCard),
        ),
        matching: find.byType(UserAvatar),
      ),
    );
    final name = tester.getRect(find.text('Dara'));

    await tester.tap(find.text('Dara'));
    await tester.pump();
    // A route is kept offstage for its first frame.
    await tester.pump(Duration.zero);
    final route = ModalRoute.of(
      tester.element(find.byType(PublisherProfilePage)),
    );
    expect(route, isA<CircularRevealRoute<dynamic>>());
    // The circle it shows through starts on the avatar.
    final reveal = tester.widget<ClipPath>(
      find
          .ancestor(
            of: find.byType(PublisherProfilePage),
            matching: find.byType(ClipPath),
          )
          .first,
    );
    final circle = reveal.clipper!.getClip(const Size(390, 844)).getBounds();
    expect(circle.center, avatar.center);
    expect(circle.width, closeTo(avatar.width, 1));
    await _settle(tester);

    // The listing is on both pages, but only the circle moves: its card on
    // the profile is not a hero the feed's card flies into.
    expect(
      find.text('Shophouse Corner', skipOffstage: false),
      findsNWidgets(2),
    );
    final heroTags = tester
        .widgetList<Hero>(find.byType(Hero, skipOffstage: false))
        .map((hero) => hero.tag)
        .toList();
    expect(heroTags.toSet().length, heroTags.length);

    Navigator.of(tester.element(find.byType(PublisherProfilePage))).pop();
    await tester.pumpAndSettle();
    // Back on the same listing, the feed where it was.
    expect(find.byType(PublisherProfilePage), findsNothing);
    expect(tester.getRect(find.text('Dara')).top, closeTo(name.top, 4));
  });

  testWidgets('empty: explains following, and "Explore" goes to the map', (
    tester,
  ) async {
    final container = await _pumpFeed(tester, _api((_) => _page([])));
    container.read(mainNavProvider.notifier).setIndex(MainTab.feed);

    expect(find.text('Your feed is empty'), findsOneWidget);
    await tester.tap(find.text('Explore listings'));
    await tester.pump();

    expect(container.read(mainNavProvider).currentIndex, MainTab.explore);
  });

  testWidgets('a failure offers a retry that loads the feed', (tester) async {
    var failing = true;
    await _pumpFeed(
      tester,
      _api((_) => failing ? 'fail' : _page([_listing('p-1', 'Villa')])),
    );

    expect(find.text('Your feed could not be loaded.'), findsOneWidget);
    failing = false;
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(find.text('Villa'), findsOneWidget);
  });

  testWidgets('reads the feed again after a follow changes', (tester) async {
    var followed = false;
    final server = _api(
      (_) => _page([
        _listing('p-1', 'Villa'),
        if (followed) _listing('p-9', 'New condo', owner: 'Dara'),
      ]),
    );
    final container = await _pumpFeed(tester, server);
    expect(find.text('Dara'), findsNothing);

    followed = true;
    container.read(followChangesProvider.notifier).state++;
    await _settle(tester);

    expect(_feedRequests(server), hasLength(2));
    expect(find.text('Villa'), findsOneWidget, reason: 'kept while reloading');
    await tester.scrollUntilVisible(find.text('Dara'), 200);
  });

  testWidgets('loads the next page from the cursor, and stops at the end', (
    tester,
  ) async {
    final server = _api(
      (cursor) => switch (cursor) {
        null => _page([
          for (var i = 0; i < 20; i++) _listing('a-$i', 'First $i'),
        ], next: 'after-a-19'),
        'after-a-19' => _page([_listing('b-0', 'Second page')]),
        _ => 'fail',
      },
    );
    await _pumpFeed(tester, server);

    await tester.scrollUntilVisible(find.text('First 19'), 400);
    await _settle(tester);
    await tester.scrollUntilVisible(find.text('Second page'), 400);
    await _settle(tester);

    final asked = server.requests
        .where((r) => r.path == '/feed')
        .map((r) => r.body)
        .toList();
    expect(asked, hasLength(2), reason: 'no third page after the last');
  });

  testWidgets('a guest asks the server for nothing', (tester) async {
    final server = _api((_) => _page([_listing('p-1', 'Villa')]));
    await _pumpFeed(tester, server, signedIn: false);

    expect(_feedRequests(server), isEmpty);
    expect(find.text('Your feed is empty'), findsOneWidget);
  });

  group('kept on the device', () {
    testWidgets('the first page is kept for next time, for this account', (
      tester,
    ) async {
      await _pumpFeed(tester, _api((_) => _page([_listing('p-1', 'Villa')])));

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_keptKey), contains('Villa'));
    });

    testWidgets('starting offline shows the kept page instead of an error', (
      tester,
    ) async {
      await _pumpFeed(
        tester,
        _api((_) => 'fail'),
        kept: {
          _keptKey: _page([_listing('p-1', 'Kept villa')]),
        },
      );

      expect(find.text('Kept villa'), findsOneWidget);
      expect(find.text('Your feed could not be loaded.'), findsNothing);
    });

    testWidgets('the kept page is replaced by the server\'s', (tester) async {
      final server = _api((_) => _page([_listing('p-2', 'New condo')]));
      await _pumpFeed(
        tester,
        server,
        kept: {
          _keptKey: _page([_listing('p-1', 'Kept villa')]),
        },
      );

      expect(_feedRequests(server), hasLength(1));
      expect(find.text('New condo'), findsOneWidget);
      expect(find.text('Kept villa'), findsNothing);
    });

    testWidgets('another account\'s kept page is never shown', (tester) async {
      await _pumpFeed(
        tester,
        _api((_) => 'fail'),
        kept: {
          'feed.first_page.v1.someone-else': _page([
            _listing('p-1', 'Their villa'),
          ]),
        },
      );

      expect(find.text('Their villa'), findsNothing);
      expect(find.text('Your feed could not be loaded.'), findsOneWidget);
    });
  });

  group('freshness', () {
    testWidgets('showing the tab again reads the feed only once it is old', (
      tester,
    ) async {
      final clock = _Clock();
      final server = _api((_) => _page([_listing('p-1', 'Villa')]));
      final container = await _pumpFeed(tester, server, clock: clock);
      final nav = container.read(mainNavProvider.notifier);
      nav.setIndex(MainTab.feed);
      await _settle(tester);
      expect(_feedRequests(server), hasLength(1), reason: 'just read');

      nav.setIndex(MainTab.chat);
      clock.now = clock.now.add(const Duration(minutes: 4));
      nav.setIndex(MainTab.feed);
      await _settle(tester);
      expect(_feedRequests(server), hasLength(1), reason: '4 minutes old');

      nav.setIndex(MainTab.chat);
      clock.now = clock.now.add(const Duration(minutes: 2));
      nav.setIndex(MainTab.feed);
      await _settle(tester);
      expect(_feedRequests(server), hasLength(2), reason: '6 minutes old');
    });

    testWidgets('a failed pull-to-refresh says so and keeps the listings', (
      tester,
    ) async {
      var failing = false;
      await _pumpFeed(
        tester,
        _api((_) => failing ? 'fail' : _page([_listing('p-1', 'Villa')])),
      );

      failing = true;
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Villa'), findsOneWidget);
      expect(find.text('Your feed could not be loaded.'), findsOneWidget);
    });
  });

  testWidgets('six tabs fit a small phone, Feed right after Explore', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpTestApp(
      tester,
      const Scaffold(bottomNavigationBar: MainBottomNav()),
      overrides: [unreadCountProvider.overrideWithValue(0)],
    );

    expect(tester.takeException(), isNull);
    final explore = tester.getCenter(find.text('Explore')).dx;
    final feed = tester.getCenter(find.text('Feed')).dx;
    final saved = tester.getCenter(find.text('Saved')).dx;
    expect(explore < feed && feed < saved, isTrue);
  });
}
