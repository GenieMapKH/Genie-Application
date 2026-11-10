import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/feed/data/feed_filters.dart';
import 'package:tilomnov/features/feed/data/feed_repository.dart';
import 'package:tilomnov/features/feed/presentation/screens/feed_page.dart';
import 'package:tilomnov/features/feed/presentation/view_models/feed_provider.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/favorites_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/saved_property_ids_provider.dart';

import '../../support/test_app.dart';

PropertyModel _listing(String title) => PropertyModel(
  id: title,
  title: title,
  price: '100',
  propertyType: 'House',
  status: 'Active',
  createdAt: DateTime(2026),
);

class _DelayedFeed extends FeedRepository {
  _DelayedFeed() : super(StubServer.always(200, '{}').dio);

  final oldResponse = Completer<FeedListingsPage>();
  final requests = <Map<String, Object?>>[];
  bool holdRefresh = false;

  @override
  Future<FeedListingsPage?> savedFirstPage({
    FeedFilters filters = const FeedFilters(),
  }) async => null;

  @override
  Future<FeedListingsPage> fetchPage({
    String? cursor,
    int limit = FeedRepository.pageSize,
    FeedFilters filters = const FeedFilters(),
  }) async {
    requests.add({...filters.toQuery(), 'cursor': cursor});
    if (cursor != null) return (items: <PropertyModel>[], nextCursor: null);
    if (filters.isDefault && holdRefresh) return oldResponse.future;
    return (
      items: [_listing(filters.isDefault ? 'Original' : 'Filtered')],
      nextCursor: filters.isDefault ? 'old-cursor' : 'new-cursor',
    );
  }
}

void main() {
  testWidgets(
    'a late old refresh cannot replace filtered listings or their cursor',
    (tester) async {
      final repository = _DelayedFeed();
      await pumpTestApp(
        tester,
        const FeedPage(),
        overrides: [
          feedRepositoryProvider.overrideWithValue(repository),
          favoritesRepositoryProvider.overrideWithValue(
            FavoritesRepository(StubServer.always(200, '[]').dio),
          ),
          signedInOverride(),
        ],
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FeedPage)),
      );
      repository.holdRefresh = true;
      final oldRefresh = container.read(feedProvider.notifier).refresh();
      container.read(feedFiltersProvider.notifier).state = const FeedFilters(
        propertyType: 'House',
      );
      await tester.pumpAndSettle();
      expect(find.text('Filtered'), findsOneWidget);
      repository.oldResponse.complete((
        items: [_listing('Old result')],
        nextCursor: 'stale-cursor',
      ));
      await tester.pumpAndSettle();
      await oldRefresh;
      expect(find.text('Filtered'), findsOneWidget);
      expect(find.text('Old result'), findsNothing);
      await container.read(feedProvider.notifier).loadMore();
      expect(repository.requests.last['cursor'], 'new-cursor');
      expect(repository.requests.last['propertyType'], 'House');
    },
  );
}
