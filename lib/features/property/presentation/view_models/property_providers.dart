import 'dart:math';

import 'package:dio/dio.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(apiClientProvider));
});

class MapBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  /// Grid lines per degree, about 1 km apart: the grid the server widens
  /// every map search to (`widenToGrid`).
  static const _gridStepsPerDegree = 100;

  /// Keeps a value already on the grid there despite rounding (11.55 is
  /// stored as 11.549999...).
  static const _onGridTolerance = 1e-9;

  /// The smallest box on the server's grid that holds this one. The server
  /// answers it exactly as it answers this box, but nearby map positions now
  /// ask the same question, so earlier answers can be reused.
  MapBounds widenedToGrid() {
    double down(double value, double limit) => max(
      (value * _gridStepsPerDegree + _onGridTolerance).floorToDouble() /
          _gridStepsPerDegree,
      -limit,
    );
    double up(double value, double limit) => min(
      (value * _gridStepsPerDegree - _onGridTolerance).ceilToDouble() /
              _gridStepsPerDegree +
          0,
      limit,
    );
    return MapBounds(
      minLat: down(minLat, 90),
      maxLat: up(maxLat, 90),
      minLng: down(minLng, 180),
      maxLng: up(maxLng, 180),
    );
  }
}

final mapBoundsProvider = StateProvider<MapBounds?>((ref) => null);

class VisitedPropertyIdsNotifier extends Notifier<Set<String>> {
  static const _key = 'visited_property_ids';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList(_key);
    if (saved != null && saved.isNotEmpty) {
      state = saved.toSet();
    }
  }

  void add(String id) {
    // Already known: nothing to show differently, nor to write again.
    if (state.contains(id)) return;
    final newState = {...state, id};
    state = newState;
    _save(newState);
  }

  /// The user opened listing [id]: marks it visited on the map and, when
  /// signed in, counts them as one of its viewers. The server keeps one view
  /// per person and ignores the owner, so repeating this is harmless.
  void recordView(String id) {
    add(id);
    if (ref.read(isSignedInProvider)) {
      ref.read(propertyRepositoryProvider).markAsViewed(id);
    }
  }

  Future<void> _save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}

final visitedPropertyIdsProvider =
    NotifierProvider<VisitedPropertyIdsNotifier, Set<String>>(() {
      return VisitedPropertyIdsNotifier();
    });

/// Published listings in the area the map shows, and only those: moving the
/// map replaces them. Nothing is asked before the map reports its area,
/// since asking without one would mean every listing in the world.
class PublicPropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  /// Numbers each search, so an answer that arrives after a newer search
  /// started (the map moved again meanwhile) is dropped.
  int _search = 0;

  /// The request of the refresh in progress, given up when the map moves on.
  CancelToken? _inFlight;

  @override
  Future<List<PropertyModel>> build() async {
    ref.onDispose(() => _inFlight?.cancel());
    ref.listen(mapBoundsProvider, (_, next) {
      if (next != null) _refresh(next);
    });
    // A new filter asks again for the same area.
    ref.listen(mapPropertyFilterProvider, (_, _) {
      final bounds = ref.read(mapBoundsProvider);
      if (bounds != null) _refresh(bounds);
    });

    final search = ++_search;
    final bounds = ref.read(mapBoundsProvider);
    if (bounds == null) return const [];

    final found = await _fetch(bounds);
    // A newer search already answered: keep what it found.
    return search == _search ? found : state.valueOrNull ?? found;
  }

  Future<void> _refresh(MapBounds bounds) async {
    final search = ++_search;
    // Its answer would be dropped anyway: stop downloading and parsing it.
    _inFlight?.cancel();
    final request = _inFlight = CancelToken();
    try {
      final found = await _fetch(bounds, cancelToken: request);
      if (search == _search) state = AsyncData(found);
    } catch (e) {
      // Given up for a newer search: nothing went wrong.
      if (e is DioException && CancelToken.isCancel(e)) return;
      // A failed refresh keeps the markers already on the map.
      AppLogger.error('Map properties refresh failed', e);
    } finally {
      if (identical(_inFlight, request)) _inFlight = null;
    }
  }

  Future<List<PropertyModel>> _fetch(
    MapBounds bounds, {
    CancelToken? cancelToken,
  }) {
    final filter = ref.read(mapPropertyFilterProvider);
    final box = bounds.widenedToGrid();
    return ref
        .read(propertyRepositoryProvider)
        .fetchPublicMapProperties(
          minLat: box.minLat,
          maxLat: box.maxLat,
          minLng: box.minLng,
          maxLng: box.maxLng,
          propertyType: filter.propertyType,
          listingType: filter.listingType,
          cancelToken: cancelToken,
        );
  }
}

final publicPropertiesProvider =
    AsyncNotifierProvider<PublicPropertiesNotifier, List<PropertyModel>>(() {
      return PublicPropertiesNotifier();
    });
