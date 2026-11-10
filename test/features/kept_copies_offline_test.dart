import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';
import 'package:tilomnov/features/closest_listings/data/closest_listings_repository.dart';
import 'package:tilomnov/features/closest_listings/presentation/view_models/closest_listings_provider.dart';
import 'package:tilomnov/features/profile/data/repositories/user_repository.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/data/repositories/favorites_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/map_property_filter.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';

import '../support/test_app.dart';
import 'chat/chat_fakes.dart';

String _listing(String id) =>
    '{"id": "$id", "title": "Listing $id", "price": "120000", '
    '"propertyType": "Land", "listingType": "Sale", "status": "Active", '
    '"createdAt": "2026-07-01T00:00:00.000Z", "lat": 11.55, "lng": 104.92, '
    '"images": [], "user": {"id": "owner", "name": "Sokha"}, '
    '"distanceMeters": 450}';

const _profileJson =
    '{"id":"u1","email":"sokha@example.com","phone":null,"username":"sokha",'
    '"name":"Sokha Chan","firstName":"Sokha","lastName":null,"sex":"female",'
    '"role":"user","createdAt":"2026-01-01T00:00:00.000Z","avatarUrl":null}';

/// The API, answering [listings] (by path) until [offline] is set.
class _Api {
  bool offline = false;
  List<String> listings;

  _Api(this.listings);

  late final server = StubServer((options) {
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return switch (options.path) {
      '/users/me' => (200, _profileJson),
      '/properties/my/favorites/ids' => (200, '[]'),
      _ => (
        200,
        '{"items": [${listings.map(_listing).join(', ')}], '
            '"nextOffset": null}',
      ),
    };
  });
}

Future<String?> _me() async => 'u1';

void main() {
  final status = NetworkStatus.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    status.reset();
  });
  tearDown(status.reset);

  /// A fresh start of the app, on [api].
  ProviderContainer appOn(_Api api) {
    final container = ProviderContainer(
      overrides: [
        signedInOverride(),
        favoritesRepositoryProvider.overrideWithValue(
          FavoritesRepository(api.server.dio, accountId: _me),
        ),
        userRepositoryProvider.overrideWithValue(
          UserRepository(api.server.dio, accountId: _me),
        ),
        closestListingsRepositoryProvider.overrideWithValue(
          ClosestListingsRepository(api.server.dio),
        ),
        closestOriginProvider.overrideWithValue(
          () async => (point: const LatLng(11.55, 104.92), isUser: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Saved', () {
    Future<List<String>> savedIds(ProviderContainer app) async =>
        (await app.read(
          savedPropertiesProvider.future,
        )).items.map((p) => p.id).toList();

    test('offline, opens on the listings kept from last time', () async {
      final api = _Api(['a', 'b']);
      expect(await savedIds(appOn(api)), ['a', 'b']);

      api.offline = true;
      expect(await savedIds(appOn(api)), ['a', 'b']);
    });

    test('reads them again once the internet is back', () async {
      final api = _Api(['a']);
      await savedIds(appOn(api));
      api.offline = true;
      final app = appOn(api);
      app.listen(savedPropertiesProvider, (_, _) {});
      app.listen(savedPropertyIdsProvider, (_, _) {});
      await savedIds(app);
      status.unreachable();

      api
        ..offline = false
        ..listings = ['a', 'c'];
      status.reachable();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await savedIds(app), ['a', 'c']);
    });
  });

  group('Profile', () {
    test('offline, it is the one kept from last time', () async {
      final api = _Api(const []);
      await appOn(api).read(userProfileProvider.future);

      api.offline = true;
      final profile = await appOn(api).read(userProfileProvider.future);
      expect(profile!.name, 'Sokha Chan');
    });

    test('offline with nothing kept, it is the connection error', () async {
      final api = _Api(const [])..offline = true;

      await expectLater(
        appOn(api).read(userProfileProvider.future),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Near you', () {
    test('offline, the list kept for the same filter', () async {
      final api = _Api(['a']);
      await appOn(api).read(closestListingsProvider.future);

      api.offline = true;
      final kept = await appOn(api).read(closestListingsProvider.future);
      expect(kept.listings.items.single.property.id, 'a');
    });

    test('offline, not one kept for another filter', () async {
      final api = _Api(['a']);
      await appOn(api).read(closestListingsProvider.future);

      api.offline = true;
      final app = appOn(api);
      app.read(mapPropertyFilterProvider.notifier).state =
          const MapPropertyFilter(propertyType: 'House');
      await expectLater(
        app.read(closestListingsProvider.future),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Chat list', () {
    test('offline, shows the conversations kept from last time', () async {
      final repository = FakeChatRepository()
        ..kept = (
          items: [
            ChatConversation.fromJson({
              'participantId': peer,
              'participantName': 'Dara',
              'unreadCount': 1,
            }),
          ],
          nextCursor: null,
          unreadTotal: 1,
        )
        ..conversationsError = DioException(
          requestOptions: RequestOptions(path: '/chat/conversations'),
          type: DioExceptionType.connectionError,
        );
      final notifier = ConversationsNotifier(
        repository: repository,
        socketService: FakeChatSocket(),
        cipher: FakeCipher(),
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.hasError, isFalse);
      expect(notifier.state.value!.items.single.participantName, 'Dara');
      expect(notifier.state.value!.unreadTotal, 1);
    });
  });
}
