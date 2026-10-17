import 'package:genie/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:genie/features/property/presentation/view_models/map_property_filter.dart';
import 'package:genie/features/property/presentation/view_models/property_visibility.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(apiClientProvider));
});

class PropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  @override
  Future<List<PropertyModel>> build() async {
    final repo = ref.watch(propertyRepositoryProvider);
    return repo.fetchAll(forceRefresh: true);
  }

  void addProperty(PropertyModel property) {
    if (state.hasValue) {
      state = AsyncData([...state.value!, property]);
    }
  }

  Future<void> publishProperty(String id) async {
    // Optimistic UI update
    if (state.hasValue) {
      state = AsyncData(
        state.value!
            .map((p) => p.id == id ? p.copyWith(status: 'Active') : p)
            .toList(),
      );
    }
    await ref.read(propertyRepositoryProvider).publish(id);
    _silentRefresh();
  }

  Future<void> unpublishProperty(String id) async {
    // Optimistic UI update
    if (state.hasValue) {
      state = AsyncData(
        state.value!
            .map((p) => p.id == id ? p.copyWith(status: 'Draft') : p)
            .toList(),
      );
    }
    await ref.read(propertyRepositoryProvider).unpublish(id);
    _silentRefresh();
  }

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
    final repo = ref.read(propertyRepositoryProvider);
    await switch (change) {
      VisibilityChange.publish => repo.publish(id),
      VisibilityChange.relist => repo.relist(id),
      VisibilityChange.unpublish => repo.unpublish(id),
      VisibilityChange.markSold => repo.markSold(id),
    };
    await _silentRefresh();
  }

  /// Fetches the user's listings again without showing a loading state.
  Future<void> refreshQuietly() => _silentRefresh();

  Future<void> removeProperty(String id) async {
    // Optimistic UI update
    if (state.hasValue) {
      state = AsyncData(state.value!.where((p) => p.id != id).toList());
    }
    await ref.read(propertyRepositoryProvider).remove(id);
    _silentRefresh();
  }

  Future<void> _silentRefresh() async {
    // Fetches without setting state to AsyncLoading, avoiding full screen reload
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final properties = await repo.fetchAll(forceRefresh: true);
      state = AsyncData(properties);
    } catch (e) {
      // Revert or show error if needed, for now just ignore background sync error
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(propertyRepositoryProvider);
      return repo.fetchAll(forceRefresh: true);
    });
  }
}

final propertiesProvider =
    AsyncNotifierProvider<PropertiesNotifier, List<PropertyModel>>(() {
      return PropertiesNotifier();
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
    final newState = {...state, id};
    state = newState;
    _save(newState);
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

  @override
  Future<List<PropertyModel>> build() async {
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
    try {
      final found = await _fetch(bounds);
      if (search == _search) state = AsyncData(found);
    } catch (e) {
      // A failed refresh keeps the markers already on the map.
      AppLogger.error('Map properties refresh failed', e);
    }
  }

  Future<List<PropertyModel>> _fetch(MapBounds bounds) {
    final filter = ref.read(mapPropertyFilterProvider);
    return ref
        .read(propertyRepositoryProvider)
        .fetchPublicMapProperties(
          minLat: bounds.minLat,
          maxLat: bounds.maxLat,
          minLng: bounds.minLng,
          maxLng: bounds.maxLng,
          propertyType: filter.propertyType,
          listingType: filter.listingType,
        );
  }
}

final publicPropertiesProvider =
    AsyncNotifierProvider<PublicPropertiesNotifier, List<PropertyModel>>(() {
      return PublicPropertiesNotifier();
    });
