import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      state = AsyncData(state.value!.map((p) => p.id == id ? p.copyWith(status: 'Active') : p).toList());
    }
    await ref.read(propertyRepositoryProvider).publish(id);
    _silentRefresh();
  }

  Future<void> unpublishProperty(String id) async {
    // Optimistic UI update
    if (state.hasValue) {
      state = AsyncData(state.value!.map((p) => p.id == id ? p.copyWith(status: 'Draft') : p).toList());
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

final publicPropertiesProvider = FutureProvider<List<PropertyModel>>((
  ref,
) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.fetchPublicMapProperties();
});
