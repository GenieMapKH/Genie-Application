import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

/// The signed-in user's own listings (drafts too) inside the area the map
/// shows, so the map can mark them for editing. Read again when the map
/// moves or the listings change; none for a guest.
class OwnMapPropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  /// Numbers each read, so an answer overtaken by a newer one is dropped.
  int _search = 0;

  /// The read in progress, given up when a newer one starts.
  CancelToken? _inFlight;

  @override
  Future<List<PropertyModel>> build() async {
    _search++;
    _inFlight?.cancel();
    if (!ref.watch(isSignedInProvider)) return const [];

    ref.onDispose(() => _inFlight?.cancel());
    ref.listen(mapBoundsProvider, (_, next) {
      if (next != null) _refresh(next);
    });
    ref.listen(ownListingsRevisionProvider, (_, _) {
      final bounds = ref.read(mapBoundsProvider);
      if (bounds != null) _refresh(bounds);
    });

    final bounds = ref.read(mapBoundsProvider);
    if (bounds == null) return const [];
    return _fetch(bounds);
  }

  Future<void> _refresh(MapBounds bounds) async {
    final search = ++_search;
    _inFlight?.cancel();
    final request = _inFlight = CancelToken();
    try {
      final found = await _fetch(bounds, cancelToken: request);
      if (search == _search) state = AsyncData(found);
    } catch (e) {
      // Given up for a newer read: nothing went wrong.
      if (e is DioException && CancelToken.isCancel(e)) return;
      // A failed read keeps the listings already on the map.
      AppLogger.error('Reading your listings on the map failed', e);
    } finally {
      if (identical(_inFlight, request)) _inFlight = null;
    }
  }

  Future<List<PropertyModel>> _fetch(
    MapBounds bounds, {
    CancelToken? cancelToken,
  }) {
    final box = bounds.widenedToGrid();
    return ref
        .read(propertyRepositoryProvider)
        .fetchOwnInArea(
          minLat: box.minLat,
          maxLat: box.maxLat,
          minLng: box.minLng,
          maxLng: box.maxLng,
          cancelToken: cancelToken,
        );
  }
}

final ownMapPropertiesProvider =
    AsyncNotifierProvider<OwnMapPropertiesNotifier, List<PropertyModel>>(
      OwnMapPropertiesNotifier.new,
    );
