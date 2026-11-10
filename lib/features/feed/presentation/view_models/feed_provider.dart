import 'package:tilomnov/features/property/presentation/view_models/listing_refresh_provider.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/network/connection_restored_provider.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/feed/data/feed_repository.dart';
import 'package:tilomnov/features/feed/data/feed_filters.dart';
import 'package:tilomnov/features/follow/presentation/view_models/follow_providers.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(apiClientProvider));
});

/// What time it is, for how old the feed shown is. Replaced in tests.
final feedClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final feedFiltersProvider = StateProvider<FeedFilters>(
  (ref) => const FeedFilters(),
);

/// The Feed tab: listings of the people the user follows, a page at a time.
///
/// Opens on the first page kept from last time, read again behind it. Read
/// again, keeping what is shown, after each follow or unfollow, and when the
/// tab is shown or the app comes back after [staleAfter], and when the
/// internet comes back. None for a guest.
class FeedNotifier extends AsyncNotifier<PagedList<PropertyModel>> {
  /// How old what is shown may get before showing the tab reads it again.
  static const staleAfter = Duration(seconds: 30);

  String? _nextCursor;

  /// When the first page last came from the server; null while only the
  /// kept one is shown.
  DateTime? _loadedAt;

  /// Counts reloads, so a page that was on its way during one is dropped.
  int _generation = 0;

  @override
  Future<PagedList<PropertyModel>> build() async {
    final generation = ++_generation;
    _nextCursor = null;
    _loadedAt = null;
    final repository = ref.watch(feedRepositoryProvider);
    final filters = ref.watch(feedFiltersProvider);
    if (!ref.watch(isSignedInProvider)) return const PagedList();

    ref.listen(listingRefreshProvider, (_, _) {
      if (ref.read(mainNavProvider).currentIndex == MainTab.feed) {
        _reloadQuietly();
      }
    });
    ref.listen(followChangesProvider, (_, _) => _reloadQuietly());
    ref.listen(connectionRestoredProvider, (_, _) => _reloadQuietly());
    ref.listen(
      mainNavProvider.select((nav) => nav.currentIndex == MainTab.feed),
      (_, shown) {
        if (shown) _reloadIfStale();
      },
    );
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (ref.read(mainNavProvider).currentIndex == MainTab.feed) {
          _reloadIfStale();
        }
      },
    );
    ref.onDispose(lifecycle.dispose);

    final saved = await repository.savedFirstPage(filters: filters);
    if (generation != _generation) return const PagedList();
    if (saved != null) {
      // Shown at once; the server's page replaces it when it arrives.
      _nextCursor = saved.nextCursor;
      unawaited(Future.microtask(_reloadQuietly));
      return _listOf(saved);
    }
    return _firstPage();
  }

  Future<PagedList<PropertyModel>> _firstPage() async {
    final generation = _generation;
    final shown = state.valueOrNull?.items.length ?? FeedRepository.pageSize;
    final page = await ref
        .read(feedRepositoryProvider)
        .fetchPage(
          limit: shown.clamp(FeedRepository.pageSize, 50),
          filters: ref.read(feedFiltersProvider),
        );
    if (generation == _generation) {
      _nextCursor = page.nextCursor;
      _loadedAt = ref.read(feedClockProvider)();
    }
    return _listOf(page);
  }

  static PagedList<PropertyModel> _listOf(FeedListingsPage page) =>
      PagedList(items: page.items, hasMore: page.nextCursor != null);

  /// The next page, added after those already shown.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final cursor = _nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;

    final generation = _generation;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(feedRepositoryProvider)
          .fetchPage(cursor: cursor, filters: ref.read(feedFiltersProvider));
      if (generation != _generation) return;
      _nextCursor = page.nextCursor;
      state = AsyncData(
        current.appended(
          page.items,
          hasMore: page.nextCursor != null,
          idOf: (p) => p.id,
        ),
      );
    } catch (e) {
      AppLogger.error('Loading more of the feed failed', e);
      if (generation == _generation) state = AsyncData(current);
    }
  }

  void _reloadIfStale() {
    final loadedAt = _loadedAt;
    final now = ref.read(feedClockProvider)();
    if (loadedAt == null || now.difference(loadedAt) > staleAfter) {
      _reloadQuietly();
    }
  }

  /// The first page again, keeping what is shown until it arrives. False
  /// when it could not be read: what is shown stays.
  Future<bool> _reloadQuietly() async {
    final generation = ++_generation;
    try {
      final reloaded = await _firstPage();
      if (generation == _generation) state = AsyncData(reloaded);
      return true;
    } catch (e) {
      AppLogger.error('Reloading the feed failed', e);
      return false;
    }
  }

  /// Pull-to-refresh. Shown listings stay until the new ones arrive; after
  /// a failure there is nothing shown, so it shows the loading state. False
  /// when the feed could not be read.
  Future<bool> refresh() async {
    if (state.hasValue && !state.hasError) return _reloadQuietly();
    _generation++;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_firstPage);
    return !state.hasError;
  }
}

final feedProvider =
    AsyncNotifierProvider<FeedNotifier, PagedList<PropertyModel>>(
      FeedNotifier.new,
    );
