import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_app.dart';

PropertyModel _listing(String id, String type, String? listing) =>
    PropertyModel.fromJson({
      'id': id,
      'title': id,
      'price': '1',
      'propertyType': type,
      'listingType': listing,
      'status': 'Active',
      'createdAt': '2026-10-01T00:00:00.000Z',
    });

/// The signed-in user's own listings; the public feed stays empty.
class _OwnListings extends PropertyRepository {
  final List<PropertyModel> mine;

  _OwnListings(this.mine) : super(Dio());

  @override
  Future<List<PropertyModel>> fetchAll({bool forceRefresh = false}) async =>
      mine;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MapPropertyFilter', () {
    final house = _listing('h', 'House', 'Rent');

    test('matches everything while empty', () {
      expect(const MapPropertyFilter().matches(house), isTrue);
      expect(const MapPropertyFilter().isEmpty, isTrue);
    });

    test('needs both the type and the listing type to match', () {
      const filter = MapPropertyFilter(
        propertyType: 'House',
        listingType: 'Sale',
      );
      expect(filter.matches(house), isFalse);
      expect(filter.toggleListing('Rent').matches(house), isTrue);
    });

    test('picking the selected pill again clears it', () {
      const filter = MapPropertyFilter(propertyType: 'Land');
      expect(filter.toggleType('Land').propertyType, isNull);
      expect(filter.toggleType('Condo').propertyType, 'Condo');
      expect(
        filter.toggleListing('Sale').toggleListing('Sale').listingType,
        isNull,
      );
    });
  });

  test('the user\'s own listings on the map obey the filter too', () async {
    final container = ProviderContainer(
      overrides: [
        signedInOverride(),
        propertyRepositoryProvider.overrideWithValue(
          _OwnListings([
            _listing('land-sale', 'Land', 'Sale'),
            _listing('house-rent', 'House', 'Rent'),
            _listing('old-land', 'Land', null),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(propertiesProvider.future);

    List<String> shown() => [
      for (final p in container.read(mapPropertiesProvider).properties) p.id,
    ];

    expect(shown(), ['land-sale', 'house-rent', 'old-land']);

    container.read(mapPropertyFilterProvider.notifier).state =
        const MapPropertyFilter(propertyType: 'Land');
    expect(shown(), ['land-sale', 'old-land']);

    container.read(mapPropertyFilterProvider.notifier).state =
        const MapPropertyFilter(propertyType: 'Land', listingType: 'Sale');
    expect(shown(), ['land-sale']);
  });
}
