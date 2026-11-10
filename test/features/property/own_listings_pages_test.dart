import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_tab.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_visibility.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

import '../../support/test_app.dart';

PropertyModel _listing(String id, String status) => PropertyModel.fromJson({
  'id': id,
  'title': id,
  'price': '1',
  'propertyType': 'House',
  'status': status,
  'createdAt': '2026-10-01T00:00:00.000Z',
});

/// The user's listings on the server, served a page at a time; what is
/// asked is recorded, and a publish can be made to fail.
class _Server extends PropertyRepository {
  List<PropertyModel> listings;
  final offsets = <int>[];
  final statusesAsked = <List<String>>[];
  bool refusePublish = false;
  Completer<void>? publishGate;

  _Server(this.listings) : super(Dio());

  Map<String, int> get _counts {
    final counts = <String, int>{};
    for (final p in listings) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<OwnListingsPage> fetchOwnPage({
    required int offset,
    int limit = PropertyRepository.ownPageSize,
    List<String> statuses = const [],
  }) async {
    offsets.add(offset);
    statusesAsked.add(statuses);
    final end = (offset + limit).clamp(0, listings.length);
    return (
      items: listings.sublist(offset.clamp(0, end), end),
      nextOffset: end < listings.length ? end : null,
      countByStatus: _counts,
    );
  }

  @override
  Future<PropertyModel> publish(String id) async {
    await publishGate?.future;
    if (refusePublish) throw Exception('refused');
    listings = [
      for (final p in listings) p.id == id ? p.copyWith(status: 'Active') : p,
    ];
    return listings.firstWhere((p) => p.id == id);
  }

  @override
  Future<PropertyModel> markSold(String id) async {
    listings = [
      for (final p in listings) p.id == id ? p.copyWith(status: 'Sold') : p,
    ];
    return listings.firstWhere((p) => p.id == id);
  }

  @override
  Future<void> remove(String id) async {
    listings = listings.where((p) => p.id != id).toList();
  }
}

List<String> _ids(OwnListings listings) => [
  for (final p in listings.items) p.id,
];

void main() {
  late _Server server;
  late ProviderContainer container;

  setUp(() {
    server = _Server([
      for (var i = 0; i < 25; i++) _listing('p$i', i < 5 ? 'Draft' : 'Active'),
    ]);
    container = ProviderContainer(
      overrides: [
        signedInOverride(),
        propertyRepositoryProvider.overrideWithValue(server),
      ],
    );
    addTearDown(container.dispose);
    container.listen(propertiesProvider, (_, _) {});
  });

  OwnListings shown() => container.read(propertiesProvider).requireValue;

  test('loads a page, then the next one, with every count', () async {
    final first = await container.read(propertiesProvider.future);
    expect(first.items, hasLength(PropertyRepository.ownPageSize));
    expect(first.page.hasMore, isTrue);
    expect(first.countByStatus, {'Draft': 5, 'Active': 20});

    await container.read(propertiesProvider.notifier).loadMore();

    expect(_ids(shown()), [for (var i = 0; i < 25; i++) 'p$i']);
    expect(shown().page.hasMore, isFalse);
    expect(server.offsets, [0, 20]);
  });

  test(
    'a listing that shifted onto the next page is not shown twice',
    () async {
      await container.read(propertiesProvider.future);
      // A new listing on the server pushes p19 onto the second page.
      server.listings = [_listing('new', 'Draft'), ...server.listings];

      await container.read(propertiesProvider.notifier).loadMore();

      final ids = _ids(shown());
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, contains('p24'));
    },
  );

  test('asks for nothing more after the last page', () async {
    await container.read(propertiesProvider.future);
    await container.read(propertiesProvider.notifier).loadMore();
    await container.read(propertiesProvider.notifier).loadMore();

    expect(server.offsets, [0, 20]);
  });

  test('a publish moves its count only after server confirmation', () async {
    server.publishGate = Completer<void>();
    await container.read(propertiesProvider.future);
    final publishing = container
        .read(propertiesProvider.notifier)
        .changeVisibility('p0', 'Draft', PropertyVisibility.public);

    await pumpEventQueue();
    expect(shown().count('Draft'), 5);
    expect(shown().count('Active'), 20);
    expect(shown().items.first.status, 'Draft');
    server.publishGate!.complete();
    await publishing;
    expect(shown().count('Draft'), 4);
    expect(shown().count('Active'), 21);
    expect(shown().items.first.status, 'Active');
  });

  test('a refused publish never changes the card or tab counts', () async {
    server.refusePublish = true;
    await container.read(propertiesProvider.future);
    final counts = <Map<String, int>>[];
    container.listen(propertiesProvider, (_, next) {
      if (next.hasValue) counts.add(next.requireValue.countByStatus);
    });

    await expectLater(
      container
          .read(propertiesProvider.notifier)
          .changeVisibility('p0', 'Draft', PropertyVisibility.public),
      throwsException,
    );
    await pumpEventQueue();

    expect(shown().count('Draft'), 5);
    expect(shown().items.first.status, 'Draft');
    expect(
      counts.every((count) => count['Draft'] == 5 && count['Active'] == 20),
      isTrue,
    );
  });

  test('marking an active listing sold moves its count to Sold', () async {
    await container.read(propertiesProvider.future);
    final active = shown().items.firstWhere((p) => p.status == 'Active');

    await container
        .read(propertiesProvider.notifier)
        .changeVisibility(active.id, 'Active', PropertyVisibility.sold);

    expect(shown().count('Sold'), 1);
    expect(shown().count('Active'), 19);
  });

  test('a listing moved to another tab leaves after confirmation', () async {
    await container.read(propertiesProvider.future);
    final moving = container
        .read(propertiesProvider.notifier)
        .changeVisibility('p7', 'Active', PropertyVisibility.sold);

    expect(_ids(shown()), contains('p7'));
    await moving;
    expect(_ids(shown()), isNot(contains('p7')));
    expect(shown().count('Sold'), 1);
  });

  test('a tab asks the server only for its statuses', () async {
    await container.read(propertiesProvider.future);
    expect(server.statusesAsked.last, ['Active']);

    container.read(ownListingsTabProvider.notifier).state =
        OwnListingsTab.draft;
    await container.read(propertiesProvider.future);

    expect(server.statusesAsked.last, ['Draft', 'Expired']);
  });

  test('a move the server does not allow is refused before asking', () async {
    await container.read(propertiesProvider.future);

    await expectLater(
      container
          .read(propertiesProvider.notifier)
          .changeVisibility('p0', 'Draft', PropertyVisibility.sold),
      throwsStateError,
    );
    expect(shown().count('Draft'), 5);
  });

  test('a removal leaves the list and its count at once', () async {
    await container.read(propertiesProvider.future);
    final removing = container
        .read(propertiesProvider.notifier)
        .removeProperty('p7');

    expect(_ids(shown()), isNot(contains('p7')));
    expect(shown().count('Active'), 19);
    await removing;
  });

  test('a change made elsewhere reloads what is shown, quietly', () async {
    await container.read(propertiesProvider.future);
    await container.read(propertiesProvider.notifier).loadMore();
    server.listings = server.listings.sublist(1);
    final states = <AsyncValue<OwnListings>>[];
    container.listen(propertiesProvider, (_, next) => states.add(next));

    ownListingsChanged(container.read(_refProvider));
    await pumpEventQueue();

    expect(states.where((s) => s.isLoading), isEmpty);
    expect(shown().items, hasLength(24));
    expect(shown().count('Draft'), 4);
  });

  group('OwnListings.withStatus', () {
    final listings = OwnListings(
      page: PagedList(items: [_listing('a', 'Draft'), _listing('b', 'Sold')]),
      countByStatus: const {'Draft': 3, 'Sold': 1},
    );

    test('moves one count to the new status', () {
      final moved = listings.withStatus('a', 'Active');
      expect(moved.countByStatus, {'Draft': 2, 'Sold': 1, 'Active': 1});
    });

    test('drops a status that reaches zero', () {
      expect(listings.withStatus('b', null).countByStatus, {'Draft': 3});
    });

    test('takes a listing out when its tab does not list the new status', () {
      final moved = listings.withStatus(
        'a',
        'Active',
        listed: OwnListingsTab.draft.lists,
      );
      expect(moved.items.map((p) => p.id), ['b']);
      expect(moved.countByStatus, {'Draft': 2, 'Sold': 1, 'Active': 1});
    });

    test('changes nothing for a listing that is not loaded', () {
      expect(identical(listings.withStatus('zz', 'Active'), listings), isTrue);
    });
  });

  test('the Draft tab counts expired listings too', () {
    expect(OwnListingsTab.draft.countIn({'Draft': 2, 'Expired': 1}), 3);
    expect(OwnListingsTab.pending.countIn({'Draft': 2}), 0);
  });
}

/// A `Ref` for calling `ownListingsChanged` the way a provider does.
final _refProvider = Provider<Ref>((ref) => ref);
