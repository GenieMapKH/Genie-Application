import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_visibility.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

/// Counts up whenever the signed-in user's own listings change (created,
/// edited, moved, published, hidden, sold, deleted), wherever that happened:
/// what shows those listings reads them again.
final ownListingsRevisionProvider = StateProvider<int>((ref) => 0);

/// Tells everything showing the user's own listings that they changed.
void ownListingsChanged(Ref ref) =>
    ref.read(ownListingsRevisionProvider.notifier).state++;

/// The same, from a widget.
void ownListingsChangedFrom(WidgetRef ref) =>
    ref.read(ownListingsRevisionProvider.notifier).state++;

/// The signed-in user's own listings, newest first, a page at a time, with
/// their count per status: the My Properties screen. None for a guest.
class PropertiesNotifier extends AsyncNotifier<OwnListings> {
  int? _nextOffset;

  /// Counts reloads, so a page that was on its way during one is dropped.
  int _generation = 0;

  /// The most one quiet reload reads back (the server's page limit).
  static const _maxReload = 50;

  @override
  Future<OwnListings> build() async {
    final repo = ref.watch(propertyRepositoryProvider);
    _generation++;
    _nextOffset = null;
    if (!ref.watch(isSignedInProvider)) return const OwnListings();
    ref.listen(ownListingsRevisionProvider, (_, _) => _reloadQuietly());
    return _firstPage(repo, PropertyRepository.ownPageSize);
  }

  Future<OwnListings> _firstPage(PropertyRepository repo, int limit) async {
    final page = await repo.fetchOwnPage(offset: 0, limit: limit);
    _nextOffset = page.nextOffset;
    return OwnListings(
      page: PagedList(items: page.items, hasMore: page.nextOffset != null),
      countByStatus: page.countByStatus,
    );
  }

  /// The next page, added after those already shown.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final offset = _nextOffset;
    if (current == null || offset == null || current.page.loadingMore) return;

    final generation = _generation;
    state = AsyncData(
      current.copyWith(page: current.page.copyWith(loadingMore: true)),
    );
    try {
      final page = await ref
          .read(propertyRepositoryProvider)
          .fetchOwnPage(offset: offset);
      if (generation != _generation) return;
      _nextOffset = page.nextOffset;
      state = AsyncData(
        OwnListings(
          page: current.page.appended(
            page.items,
            hasMore: page.nextOffset != null,
            idOf: (p) => p.id,
          ),
          countByStatus: page.countByStatus,
        ),
      );
    } catch (e) {
      AppLogger.error('Loading more of your listings failed', e);
      if (generation == _generation) state = AsyncData(current);
    }
  }

  Future<void> publishProperty(String id) =>
      _changeOptimistically(id, 'Active', (repo) => repo.publish(id));

  Future<void> unpublishProperty(String id) =>
      _changeOptimistically(id, 'Draft', (repo) => repo.unpublish(id));

  Future<void> removeProperty(String id) =>
      _changeOptimistically(id, null, (repo) => repo.remove(id));

  /// Shows listing [id] in [status] (or gone, when null) at once, then asks
  /// the server. Whether it agreed or not, the listings are read again, so
  /// a refused change is undone on screen too.
  Future<void> _changeOptimistically(
    String id,
    String? status,
    Future<Object?> Function(PropertyRepository) request,
  ) async {
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(current.withStatus(id, status));
    try {
      await request(ref.read(propertyRepositoryProvider));
    } finally {
      ownListingsChanged(ref);
    }
  }

  /// Reads the pages already shown again, without a loading state.
  Future<void> _reloadQuietly() async {
    final shown = state.valueOrNull?.items.length ?? 0;
    final generation = ++_generation;
    try {
      final reloaded = await _firstPage(
        ref.read(propertyRepositoryProvider),
        shown.clamp(PropertyRepository.ownPageSize, _maxReload),
      );
      if (generation == _generation) state = AsyncData(reloaded);
    } catch (e) {
      // The listings already shown stay; the next change or pull reloads.
      AppLogger.error('Reloading your listings failed', e);
    }
  }

  /// Pull to refresh: the first page again, with a loading state.
  Future<void> refresh() async {
    _generation++;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _firstPage(
        ref.read(propertyRepositoryProvider),
        PropertyRepository.ownPageSize,
      ),
    );
  }
}

final propertiesProvider =
    AsyncNotifierProvider<PropertiesNotifier, OwnListings>(
      PropertiesNotifier.new,
    );

/// Changes to one of the user's own listings made outside the My Properties
/// list (from its detail sheet, say), so that list need not be loaded.
class OwnListingActions {
  final Ref _ref;

  const OwnListingActions(this._ref);

  /// Moves listing [id], now of [status], to [target]. Throws when the
  /// server refuses (see [visibilityChange]).
  Future<void> changeVisibility(
    String id,
    String status,
    PropertyVisibility target,
  ) async {
    final change = visibilityChange(status, target);
    if (change == null) {
      throw StateError('Cannot move a $status listing to ${target.name}');
    }
    final repo = _ref.read(propertyRepositoryProvider);
    await switch (change) {
      VisibilityChange.publish => repo.publish(id),
      VisibilityChange.relist => repo.relist(id),
      VisibilityChange.unpublish => repo.unpublish(id),
      VisibilityChange.markSold => repo.markSold(id),
    };
    ownListingsChanged(_ref);
  }
}

final ownListingActionsProvider = Provider<OwnListingActions>(
  OwnListingActions.new,
);
