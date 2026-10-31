import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/network/connection_restored_provider.dart';
import 'package:tilomnov/core/network/load_failure.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/closest_listings/data/closest_listing.dart';
import 'package:tilomnov/features/closest_listings/data/closest_listings_repository.dart';
import 'package:tilomnov/features/home/presentation/providers/map_camera_provider.dart';
import 'package:tilomnov/features/home/utils/map/map_location_service.dart';
import 'package:tilomnov/features/property/presentation/view_models/map_property_filter.dart';
import 'package:tilomnov/shared/utils/paged_list.dart';

final closestListingsRepositoryProvider = Provider<ClosestListingsRepository>(
  (ref) => ClosestListingsRepository(ref.watch(apiClientProvider)),
);

/// Where distances are measured from.
typedef ClosestOrigin = ({LatLng point, bool isUser});

/// The user's position when location is allowed, else the map's centre.
/// Rounded to about 100 m: the server needs no more to rank listings.
/// Replaced in tests.
final closestOriginProvider = Provider<Future<ClosestOrigin> Function()>((ref) {
  return () async {
    final position = await MapLocationService.positionIfAllowed();
    if (position != null) {
      return (
        point: _rounded(LatLng(position.latitude, position.longitude)),
        isUser: true,
      );
    }
    return (point: _rounded(ref.read(mapCameraProvider).center), isUser: false);
  };
});

LatLng _rounded(LatLng point) => LatLng(
  double.parse(point.latitude.toStringAsFixed(3)),
  double.parse(point.longitude.toStringAsFixed(3)),
);

/// The list under the map's pull-up sheet, and whether it is measured from
/// the user ([nearUser]) or from the map's centre.
class ClosestListingsState {
  final PagedList<ClosestListing> listings;
  final bool nearUser;

  const ClosestListingsState({required this.listings, required this.nearUser});

  ClosestListingsState withListings(PagedList<ClosestListing> listings) =>
      ClosestListingsState(listings: listings, nearUser: nearUser);
}

/// Every published listing, nearest first, a page at a time, passing the
/// map filter. Read when first shown and again when the filter changes,
/// from the same origin; [refresh] measures from where the user is now.
/// Without internet it is the list kept from last time (for the same
/// filter), read again once the internet is back.
class ClosestListingsNotifier extends AsyncNotifier<ClosestListingsState> {
  /// Kept across filter changes, so the list does not jump to a new origin.
  ClosestOrigin? _origin;
  int? _nextOffset;

  /// Counts reloads, so a page that was on its way during one is dropped.
  int _generation = 0;

  @override
  Future<ClosestListingsState> build() async {
    final generation = ++_generation;
    final filter = ref.watch(mapPropertyFilterProvider);
    final origin = _origin ??= await ref.read(closestOriginProvider)();
    final page = await _firstPage(origin, filter);
    if (generation == _generation) _nextOffset = page.nextOffset;
    return ClosestListingsState(
      listings: PagedList(items: page.items, hasMore: page.nextOffset != null),
      nearUser: origin.isUser,
    );
  }

  Future<ClosestListingsPage> _firstPage(
    ClosestOrigin origin,
    MapPropertyFilter filter,
  ) async {
    final repository = ref.read(closestListingsRepositoryProvider);
    try {
      return await repository.fetchPage(origin: origin.point, filter: filter);
    } catch (e) {
      if (!LoadFailure.of(e).isConnection) rethrow;
      final kept = await repository.keptFirstPage(filter);
      if (kept == null) rethrow;
      ref.listen(connectionRestoredProvider, (_, _) => ref.invalidateSelf());
      return kept;
    }
  }

  /// The next page, added after those already shown.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    final offset = _nextOffset;
    final origin = _origin;
    if (current == null ||
        offset == null ||
        origin == null ||
        current.listings.loadingMore) {
      return;
    }

    final generation = _generation;
    state = AsyncData(
      current.withListings(current.listings.copyWith(loadingMore: true)),
    );
    try {
      final page = await ref
          .read(closestListingsRepositoryProvider)
          .fetchPage(
            origin: origin.point,
            filter: ref.read(mapPropertyFilterProvider),
            offset: offset,
          );
      if (generation != _generation) return;
      _nextOffset = page.nextOffset;
      state = AsyncData(
        current.withListings(
          current.listings.appended(
            page.items,
            hasMore: page.nextOffset != null,
            idOf: (listing) => listing.property.id,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Loading more of the closest listings failed', e);
      if (generation == _generation) state = AsyncData(current);
    }
  }

  /// From the start, measured from where the user is now.
  void refresh() {
    _origin = null;
    _nextOffset = null;
    ref.invalidateSelf();
  }
}

final closestListingsProvider =
    AsyncNotifierProvider<ClosestListingsNotifier, ClosestListingsState>(
      ClosestListingsNotifier.new,
    );
