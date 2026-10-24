import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/app/navigation/chat_profile_navigation.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/providers/chat_profile_opener.dart';
import 'package:genie/features/follow/data/follow_repository.dart';
import 'package:genie/features/follow/presentation/view_models/follow_providers.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/search/data/search_history_repository.dart';
import 'package:genie/features/search/data/search_repository.dart';
import 'package:genie/features/search/presentation/screens/publisher_profile_page.dart';
import 'package:genie/features/search/presentation/screens/search_page.dart';
import 'package:genie/features/search/presentation/view_models/search_providers.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';

import '../../support/test_app.dart';

const _person =
    '{"id": "u-1", "name": "Sokha Realty", "username": "sokha_realty", '
    '"avatarUrl": null, "listingCount": 2, '
    '"memberSince": "2025-03-01T00:00:00.000Z"}';

/// The profile endpoint adds contact details; search result lists do not.
const _profilePerson =
    '{"id": "u-1", "name": "Sokha Realty", "username": "sokha_realty", '
    '"avatarUrl": null, "listingCount": 2, '
    '"memberSince": "2025-03-01T00:00:00.000Z", '
    '"email": "sokha@gmail.com", "phone": "+855 12 345 678"}';

String _listing(String id, String title) =>
    '{"id": "$id", "title": "$title", "price": "120000", "propertyType": "Land", '
    '"status": "Active", "createdAt": "2026-10-01T00:00:00.000Z", '
    '"lat": 11.52, "lng": 104.87, "images": []}';

final _searchAnswer = '{"places": [], "properties": [], "people": [$_person]}';

/// Search, then the profile and its follow counts, from one stub API. The
/// person starts with 12 followers; following answers [followStatus].
StubServer _api({
  int profileStatus = 200,
  String? listings,
  String person = _profilePerson,
  int followStatus = 200,
}) {
  var following = false;
  String follow() =>
      '{"followerCount": ${following ? 13 : 12}, "followingCount": 4, '
      '"isFollowing": $following}';
  return StubServer((request) {
    if (request.path == '/users/u-1/follow') {
      if (request.method == 'PUT') {
        if (followStatus != 200) return (followStatus, '{}');
        following = true;
      }
      if (request.method == 'DELETE') following = false;
      return (200, follow());
    }
    if (request.path == '/public/search') return (200, _searchAnswer);
    if (request.path == '/public/search/people/u-1') {
      if (profileStatus != 200) return (profileStatus, '{}');
      final items =
          listings ??
          '${_listing('p-1', 'Land near Veng Sreng')}, '
              '${_listing('p-2', 'Shophouse Corner')}';
      return (200, '{"person": $person, "properties": [$items]}');
    }
    return (404, '{}');
  });
}

/// Opens search, finds "sokha" and taps the person. Returns what search closed with.
/// Signed in as [userId], or a guest.
Override _signedInAs(String? userId) => userProfileProvider.overrideWith(
  (ref) async => userId == null
      ? throw Exception('guest')
      : UserProfile(id: userId, role: 'user', createdAt: DateTime(2026)),
);

Future<SearchSelection? Function()> _openProfile(
  WidgetTester tester,
  StubServer server, {
  Size size = const Size(390, 844),
  String? signedInAs = 'me',
  bool? hasSession,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

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
    overrides: [
      searchRepositoryProvider.overrideWithValue(SearchRepository(server.dio)),
      searchHistoryRepositoryProvider.overrideWithValue(
        SearchHistoryRepository(server.dio),
      ),
      searchHasSessionProvider.overrideWithValue(() async => false),
      followRepositoryProvider.overrideWithValue(FollowRepository(server.dio)),
      _signedInAs(signedInAs),
      signedInOverride(signedIn: hasSession ?? signedInAs != null),
    ],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'sokha');
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();

  await tester.tap(find.textContaining('Sokha Realty'));
  await tester.pumpAndSettle();
  return () => picked;
}

void main() {
  for (final (name, size) in [
    ('small phone', const Size(320, 568)),
    ('phone', const Size(390, 844)),
    ('tablet', const Size(1024, 1366)),
  ]) {
    testWidgets('shows who they are and all their listings on a $name', (
      tester,
    ) async {
      await _openProfile(tester, _api(), size: size);

      expect(find.text('Sokha Realty'), findsWidgets);
      expect(find.text('@sokha_realty'), findsOneWidget);
      expect(find.text('Member since March 2025'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      // The "Listings" tab is open first.
      expect(find.text('Listings'), findsWidgets);
      await tester.scrollUntilVisible(find.text('Shophouse Corner'), 200);
      expect(find.text('Land near Veng Sreng'), findsOneWidget);
      expect(find.text('Shophouse Corner'), findsOneWidget);
    });
  }

  testWidgets('back returns to the search results', (tester) async {
    await _openProfile(tester, _api());

    // The system back button (Android's, or a swipe).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('PEOPLE & AGENCIES'), findsOneWidget);
  });

  testWidgets('"View on map" closes search and shows their listings there', (
    tester,
  ) async {
    final picked = await _openProfile(tester, _api());

    await tester.tap(find.text('View on map'));
    await tester.pumpAndSettle();

    final target = (picked() as AreaSelection).target as PersonTarget;
    expect(target.person.id, 'u-1');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('says so when they have nothing published', (tester) async {
    await _openProfile(tester, _api(listings: ''));

    expect(
      find.text('This person has no published listings right now.'),
      findsOneWidget,
    );
    expect(find.text('View on map'), findsNothing);
  });

  testWidgets('explains a failure and retries', (tester) async {
    final server = _api(profileStatus: 500);
    await _openProfile(tester, server);

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    final before = server.requests.length;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(server.requests.length, before + 1);
  });

  testWidgets('shows how to reach them, and copies it with a tap', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _openProfile(tester, _api());
    // Not on the first tab.
    expect(find.text('sokha@gmail.com'), findsNothing);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('sokha@gmail.com'), 100);
    expect(find.text('CONTACT'), findsNothing);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('+855 12 345 678'), findsOneWidget);
    expect(find.text('sokha@gmail.com'), findsOneWidget);

    await tester.tap(find.text('+855 12 345 678'));
    await tester.pump();
    expect(copied, ['+855 12 345 678']);
    expect(find.text('Phone copied'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('leaves out the contact card when there is nothing to show', (
    tester,
  ) async {
    await _openProfile(tester, _api(person: _person));
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('Contact'), findsNothing);
    expect(find.text('No contact details shared.'), findsOneWidget);
  });

  testWidgets('"Chat" opens a conversation with them', (tester) async {
    // Signed in, but the profile is not loaded: the page then says so
    // instead of starting the encrypted session, which tests cannot run.
    await _openProfile(tester, _api(), signedInAs: null, hasSession: true);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    final chat = tester.widget<ChatConversationPage>(
      find.byType(ChatConversationPage),
    );
    expect(chat.participantId, 'u-1');
    expect(chat.participantName, 'Sokha Realty');
  });

  testWidgets('a guest who taps "Chat" is asked to sign in first', (
    tester,
  ) async {
    await _openProfile(tester, _api(), signedInAs: null);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Account Required'), findsOneWidget);
    expect(find.byType(ChatConversationPage), findsNothing);
  });

  testWidgets('your own profile has no "Chat" and no "Follow"', (tester) async {
    await _openProfile(tester, _api(), signedInAs: 'u-1');

    expect(find.text('Follow'), findsNothing);
    expect(find.text('Chat'), findsNothing);
    // Your own counts are still shown.
    expect(find.text('12 Followers'), findsOneWidget);
  });

  group('following', () {
    testWidgets('shows the counts, then follows and unfollows', (tester) async {
      final server = _api();
      await _openProfile(tester, server);

      expect(find.text('12 Followers'), findsOneWidget);
      expect(find.text('4 Following'), findsOneWidget);

      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      expect(find.text('13 Followers'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Following'), findsOneWidget);
      expect(
        server.requests.where((r) => r.method == 'PUT').single.path,
        '/users/u-1/follow',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Following'));
      await tester.pumpAndSettle();

      expect(find.text('12 Followers'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Follow'), findsOneWidget);
      expect(server.requests.where((r) => r.method == 'DELETE'), hasLength(1));
    });

    testWidgets('opened again, shows "Following" at once and checks behind', (
      tester,
    ) async {
      final server = _api();
      await _openProfile(tester, server);
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(PublisherProfilePage))).pop();
      await tester.pumpAndSettle();
      final fetches = server.requests
          .where((r) => r.method == 'GET' && r.path == '/users/u-1/follow')
          .length;
      await tester.tap(find.textContaining('Sokha Realty'));
      await tester.pump();
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Following'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Follow'), findsNothing);
      await tester.pumpAndSettle();
      expect(
        server.requests.where(
          (r) => r.method == 'GET' && r.path == '/users/u-1/follow',
        ),
        hasLength(fetches + 1),
      );
      expect(find.widgetWithText(FilledButton, 'Following'), findsOneWidget);
    });

    testWidgets('at the limit, says so and stays unfollowed', (tester) async {
      await _openProfile(tester, _api(followStatus: 409));

      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      expect(find.textContaining('up to 500 people'), findsOneWidget);
      expect(find.text('12 Followers'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Follow'), findsOneWidget);
    });

    testWidgets('when the server fails, says so and puts it back', (
      tester,
    ) async {
      await _openProfile(tester, _api(followStatus: 500));

      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      expect(
        find.text('Following could not be changed. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('12 Followers'), findsOneWidget);
    });

    testWidgets('a guest sees no counts and is asked to sign in', (
      tester,
    ) async {
      final server = _api();
      await _openProfile(tester, server, signedInAs: null);

      expect(find.textContaining('Followers'), findsNothing);
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      expect(find.text('Account Required'), findsOneWidget);
      expect(server.requests.where((r) => r.path.contains('/follow')), isEmpty);
    });
  });

  group('opened from a chat', () {
    /// A stand-in conversation whose header opens the profile the way the
    /// app wires it.
    Future<ProviderContainer> openFromChat(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpTestApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    body: Consumer(
                      builder: (context, ref, _) => TextButton(
                        onPressed: () => ref.read(chatProfileOpenerProvider)!(
                          context,
                          const ChatProfileTarget(
                            userId: 'u-1',
                            name: 'Sokha Realty',
                          ),
                        ),
                        child: const Text('chat header'),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('map'),
            ),
          ),
        ),
        overrides: [
          searchRepositoryProvider.overrideWithValue(
            SearchRepository(_api().dio),
          ),
          chatProfileOpenerProvider.overrideWith(profileFromChatOpener),
          _signedInAs('me'),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.text('map')),
      );
      container.read(mainNavProvider.notifier).setIndex(MainTab.chat);
      await tester.tap(find.text('map'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('chat header'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows the same profile page', (tester) async {
      await openFromChat(tester);

      expect(find.text('@sokha_realty'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('"Chat" goes back to the conversation', (tester) async {
      await openFromChat(tester);

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.text('chat header'), findsOneWidget);
      expect(find.byType(ChatConversationPage), findsNothing);
    });

    testWidgets('"View on map" goes to the map with their listings', (
      tester,
    ) async {
      final container = await openFromChat(tester);

      await tester.tap(find.text('View on map'));
      await tester.pumpAndSettle();

      expect(find.text('map'), findsOneWidget);
      expect(container.read(mainNavProvider).currentIndex, 0);
      final shown = container.read(searchAreaControllerProvider)!;
      expect((shown.target as PersonTarget).person.id, 'u-1');
      expect(shown.area.valueOrNull?.properties, hasLength(2));
    });
  });
}
