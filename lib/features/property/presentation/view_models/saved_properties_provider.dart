import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/favorites_repository.dart';
import 'package:genie/features/property/presentation/view_models/saved_property_ids_provider.dart';
import 'package:genie/shared/utils/paged_list.dart';

/// How saved listings are ordered. Shown with `sortOptionLabel`.
enum SortOption {
  propertyForYou,
  recentlyPosted,
  newest,
  priceHighToLow,
  priceLowToHigh,
}

final savedSortOptionProvider = StateProvider<SortOption>((ref) {
  return SortOption.propertyForYou;
});

/// The order the server sorts saved listings in for [option].
FavoriteSort favoriteSortOf(SortOption option) => switch (option) {
  SortOption.propertyForYou => FavoriteSort.saved,
  SortOption.recentlyPosted || SortOption.newest => FavoriteSort.newest,
  SortOption.priceHighToLow => FavoriteSort.priceHigh,
  SortOption.priceLowToHigh => FavoriteSort.priceLow,
};

/// The signed-in user's saved listings, a page at a time, in the chosen
/// order: the Saved screen. Follows the hearts: an unsaved listing leaves at
/// once, a newly saved one is read in quietly once the server has it. None
/// for a guest.
class SavedPropertiesNotifier extends AsyncNotifier<PagedList<PropertyModel>> {
  int? _nextOffset;

  /// Counts reloads, so a page that was on its way during one is dropped.
  int _generation = 0;

  /// The most one quiet reload reads back (the server's page limit).
  static const _maxReload = 50;

  @override
  Future<PagedList<PropertyModel>> build() async {
    _generation++;
    _nextOffset = null;
    ref.watch(favoritesRepositoryProvider);
    ref.watch(savedSortOptionProvider);
    if (!ref.watch(isSignedInProvider)) return const PagedList();
    ref.listen(savedPropertyIdsProvider, (_, next) {
      final saved = next.valueOrNull;
      if (saved != null) _dropUnsaved(saved);
    });
    ref.listen(savedListingsAddedProvider, (_, _) => _reloadQuietly());
    return _firstPage(FavoritesRepository.pageSize);
  }

  Future<PagedList<PropertyModel>> _firstPage(int limit) async {
    final page = await ref
        .read(favoritesRepositoryProvider)
        .fetchPage(offset: 0, sort: _sort, limit: limit);
    _nextOffset = page.nextOffset;
    return PagedList(items: page.items, hasMore: page.nextOffset != null);
  }

  FavoriteSort get _sort => favoriteSortOf(ref.read(savedSortOptionProvider));

  /// The next page, added after those already shown.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final offset = _nextOffset;
    if (current == null || offset == null || current.loadingMore) return;

    final generation = _generation;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(favoritesRepositoryProvider)
          .fetchPage(offset: offset, sort: _sort);
      if (generation != _generation) return;
      _nextOffset = page.nextOffset;
      state = AsyncData(
        current.appended(
          page.items,
          hasMore: page.nextOffset != null,
          idOf: (p) => p.id,
        ),
      );
    } catch (e) {
      AppLogger.error('Loading more saved listings failed', e);
      if (generation == _generation) state = AsyncData(current);
    }
  }

  /// Takes off at once the listings no longer among the [saved] ids.
  void _dropUnsaved(Set<String> saved) {
    final current = state.valueOrNull;
    if (current == null || current.items.every((p) => saved.contains(p.id))) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        items: current.items.where((p) => saved.contains(p.id)).toList(),
      ),
    );
  }

  /// Reads the pages already shown again, without a loading state.
  Future<void> _reloadQuietly() async {
    final shown = state.valueOrNull?.items.length ?? 0;
    final generation = ++_generation;
    try {
      final reloaded = await _firstPage(
        shown.clamp(FavoritesRepository.pageSize, _maxReload),
      );
      if (generation == _generation) state = AsyncData(reloaded);
    } catch (e) {
      // The listings already shown stay; the next change or retry reloads.
      AppLogger.error('Reloading saved listings failed', e);
    }
  }

  /// Retry after a failure: the first page again, with a loading state.
  Future<void> refresh() async {
    _generation++;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _firstPage(FavoritesRepository.pageSize),
    );
  }
}

final savedPropertiesProvider =
    AsyncNotifierProvider<SavedPropertiesNotifier, PagedList<PropertyModel>>(
      SavedPropertiesNotifier.new,
    );
