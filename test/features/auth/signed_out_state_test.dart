import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Profiles extends UserRepository {
  _Profiles() : super(Dio());

  @override
  Future<UserProfile> getProfile() async =>
      UserProfile(id: 'owner-1', role: 'user', createdAt: DateTime(2026));
}

final _listing = PropertyModel.fromJson({
  'id': 'property-a',
  'title': 'Property A',
  'price': '1',
  'propertyType': 'House',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
});

/// The owner's listings and favourites; counts what is asked of the server.
class _Listings extends PropertyRepository {
  int favoriteCalls = 0;

  _Listings() : super(Dio());

  @override
  Future<List<PropertyModel>> fetchAll({bool forceRefresh = false}) async => [
    _listing,
  ];

  @override
  Future<List<PropertyModel>> fetchFavorites() async => [_listing];

  @override
  Future<void> favorite(String id) async => favoriteCalls++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _Listings listings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'owner-access',
      'refresh_token': 'owner-refresh',
    });
    await AuthStorage.load();
    listings = _Listings();
    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(_Profiles()),
        propertyRepositoryProvider.overrideWithValue(listings),
      ],
    );
    addTearDown(container.dispose);
    // Kept alive the way the open screens keep them.
    container.listen(userProfileProvider, (_, _) {});
    container.listen(propertiesProvider, (_, _) {});
    container.listen(savedPropertiesProvider, (_, _) {});
  });

  test('a signed-in owner has their profile, listings and favourites', () async {
    expect((await container.read(userProfileProvider.future))?.id, 'owner-1');
    expect(await container.read(propertiesProvider.future), [_listing]);
    expect(await container.read(savedPropertiesProvider.future), [_listing]);
  });

  test(
    'after signing out nothing of the owner is left for the guest',
    () async {
      await container.read(userProfileProvider.future);
      await container.read(propertiesProvider.future);
      await container.read(savedPropertiesProvider.future);

      await AuthStorage.clearTokens();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isSignedInProvider), isFalse);
      // No profile: the listing sheet shows Chat, not the owner's Edit and
      // Visibility.
      expect(container.read(userProfileProvider).valueOrNull, isNull);
      // No edit markers on the map, and no filled hearts.
      expect(container.read(propertiesProvider).valueOrNull, isEmpty);
      expect(container.read(savedPropertiesProvider).valueOrNull, isEmpty);
    },
  );

  test('a guest cannot favourite anything', () async {
    await AuthStorage.clearTokens();
    await Future<void>.delayed(Duration.zero);

    await container
        .read(savedPropertiesProvider.notifier)
        .toggleFavorite(_listing);

    expect(listings.favoriteCalls, 0);
    expect(container.read(savedPropertiesProvider).valueOrNull, isEmpty);
  });
}
