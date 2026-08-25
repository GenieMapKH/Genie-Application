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

