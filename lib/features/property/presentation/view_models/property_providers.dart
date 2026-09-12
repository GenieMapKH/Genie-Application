import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';

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

class PublicPropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  @override
  Future<List<PropertyModel>> build() async {
    ref.listen(mapBoundsProvider, (previous, next) async {
      if (next == null) return;

      final repo = ref.read(propertyRepositoryProvider);
      try {
        final newProperties = await repo.fetchPublicMapProperties(
          minLat: next.minLat,
          maxLat: next.maxLat,
          minLng: next.minLng,
          maxLng: next.maxLng,
        );

        if (state.hasValue) {
          // Accumulate properties to prevent existing map markers from glitching/disappearing
          final merged = <String, PropertyModel>{};
          for (final p in state.value!) {
            merged[p.id] = p;
          }
          for (final p in newProperties) {
            merged[p.id] = p;
          }
          state = AsyncData(merged.values.toList());
        } else {
          state = AsyncData(newProperties);
        }
      } catch (_) {
        // Silent fail on background fetch
      }
    });

    final repo = ref.read(propertyRepositoryProvider);
    final bounds = ref.read(mapBoundsProvider);

    if (bounds != null) {
      return repo.fetchPublicMapProperties(
        minLat: bounds.minLat,
        maxLat: bounds.maxLat,
        minLng: bounds.minLng,
        maxLng: bounds.maxLng,
      );
    } else {
      return repo.fetchPublicMapProperties();
    }
  }
}

final publicPropertiesProvider =
    AsyncNotifierProvider<PublicPropertiesNotifier, List<PropertyModel>>(() {
      return PublicPropertiesNotifier();
    });
