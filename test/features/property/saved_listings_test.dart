import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/favorites_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_properties_provider.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';

import '../../support/test_app.dart';

PropertyModel _listing(String id) => PropertyModel.fromJson({
  'id': id,
  'title': id,
  'price': '1',
  'propertyType': 'House',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
});

/// The user's saved listings on the server; records what is asked, and can
/// refuse a change.
class _Server extends FavoritesRepository {
  List<String> saved;
  final pages = <({int offset, FavoriteSort sort})>[];
  bool refuse = false;

  _Server(this.saved) : super(Dio());

  @override
  Future<List<String>> fetchIds() async => [...saved];

  @override
  Future<FavoritesPage> fetchPage({
    required int offset,
    required FavoriteSort sort,
    int limit = FavoritesRepository.pageSize,
  }) async {
    pages.add((offset: offset, sort: sort));
    final end = (offset + limit).clamp(0, saved.length);
    return (
      items: [for (final id in saved.sublist(offset, end)) _listing(id)],
      nextOffset: end < saved.length ? end : null,
    );
  }

  @override
  Future<void> favorite(String id) async {
    if (refuse) throw Exception('refused');
    saved = [id, ...saved];
  }

  @override
  Future<void> unfavorite(String id) async {
    if (refuse) throw Exception('refused');
    saved = saved.where((s) => s != id).toList();
  }
}

void main() {
  late _Server server;
  late ProviderContainer container;

  setUp(() {
    server = _Server([for (var i = 0; i < 30; i++) 's$i']);
    container = ProviderContainer(
      overrides: [
        signedInOverride(),
        favoritesRepositoryProvider.overrideWithValue(server),
      ],
    );
    addTearDown(container.dispose);
    container.listen(savedPropertyIdsProvider, (_, _) {});
  });

  bool heart(String id) => container.read(isPropertySavedProvider(id));

  group('hearts', () {
    test('come from the saved ids, every one of them', () async {
      await container.read(savedPropertyIdsProvider.future);
      expect(heart('s0'), isTrue);
      expect(heart('s29'), isTrue);
      expect(heart('other'), isFalse);
    });

    test('fill at once, and the listing is saved', () async {
      await container.read(savedPropertyIdsProvider.future);
      final saving = container
          .read(savedPropertyIdsProvider.notifier)
          .toggle('new');

      expect(heart('new'), isTrue);
      expect(container.read(savedPropertyIdsProvider).value!.first, 'new');
      await saving;
      expect(server.saved.first, 'new');
    });

    test('go back when the server refuses', () async {
      server.refuse = true;
      await container.read(savedPropertyIdsProvider.future);

      await container.read(savedPropertyIdsProvider.notifier).toggle('s3');

      expect(heart('s3'), isTrue);
      expect(container.read(savedPropertyIdsProvider).value, hasLength(30));
    });
  });

  group('the Saved list', () {
    setUp(() => container.listen(savedPropertiesProvider, (_, _) {}));

    List<String> shown() => [
      for (final p in container.read(savedPropertiesProvider).value!.items)
        p.id,
    ];

    test('loads a page, then the next', () async {
      await container.read(savedPropertiesProvider.future);
      expect(shown(), hasLength(FavoritesRepository.pageSize));

      await container.read(savedPropertiesProvider.notifier).loadMore();

      expect(shown(), [for (var i = 0; i < 30; i++) 's$i']);
      expect(container.read(savedPropertiesProvider).value!.hasMore, isFalse);
    });

    test('drops an unsaved listing at once, without asking again', () async {
      await container.read(savedPropertyIdsProvider.future);
      await container.read(savedPropertiesProvider.future);
      final asked = server.pages.length;

      final unsaving = container
          .read(savedPropertyIdsProvider.notifier)
          .toggle('s2');

      expect(shown(), isNot(contains('s2')));
      await unsaving;
      expect(server.pages, hasLength(asked));
    });

    test('reads a newly saved listing in', () async {
      await container.read(savedPropertyIdsProvider.future);
      await container.read(savedPropertiesProvider.future);

      await container.read(savedPropertyIdsProvider.notifier).toggle('new');
      await pumpEventQueue();

      expect(shown().first, 'new');
    });

    test('asks the server for the chosen order', () async {
      await container.read(savedPropertiesProvider.future);
      container.read(savedSortOptionProvider.notifier).state =
          SortOption.priceLowToHigh;
      await container.read(savedPropertiesProvider.future);

      expect(server.pages.last, (offset: 0, sort: FavoriteSort.priceLow));
    });
  });

  test('every sort option has a server order', () {
    expect(favoriteSortOf(SortOption.propertyForYou), FavoriteSort.saved);
    expect(favoriteSortOf(SortOption.recentlyPosted), FavoriteSort.newest);
    expect(favoriteSortOf(SortOption.newest), FavoriteSort.newest);
    expect(favoriteSortOf(SortOption.priceHighToLow), FavoriteSort.priceHigh);
    expect(favoriteSortOf(SortOption.priceLowToHigh), FavoriteSort.priceLow);
  });
}
