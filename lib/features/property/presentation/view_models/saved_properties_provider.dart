import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/home/presentation/providers/map_properties_provider.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

enum SortOption {
  propertyForYou('Property for You'),
  recentlyPosted('Recently Posted'),
  newest('Newest'),
  priceHighToLow('Price: Hight to Low'),
  priceLowToHigh('Price: Low to Hight');

  final String label;
  const SortOption(this.label);
}

final savedSortOptionProvider = StateProvider<SortOption>((ref) {
  return SortOption.propertyForYou;
});

class SavedPropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  @override
  Future<List<PropertyModel>> build() async {
    final repo = ref.watch(propertyRepositoryProvider);
    return repo.fetchFavorites();
  }

  bool isSaved(String propertyId) {
    if (!state.hasValue) return false;
    return state.value!.any((p) => p.id == propertyId);
  }

  Future<void> toggleFavorite(PropertyModel property) async {
    final repo = ref.read(propertyRepositoryProvider);
    final currentList = state.value ?? [];
    final exists = currentList.any((p) => p.id == property.id);

    if (exists) {
      // Optimistically remove
      state = AsyncData(currentList.where((p) => p.id != property.id).toList());
      try {
        await repo.unfavorite(property.id);
      } catch (e) {
        // Rollback on failure
        state = AsyncData(currentList);
      }
    } else {
      // Optimistically add
      state = AsyncData([property, ...currentList]);
      try {
        await repo.favorite(property.id);
      } catch (e) {
        // Rollback on failure
        state = AsyncData(currentList);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(propertyRepositoryProvider);
      return repo.fetchFavorites();
    });
  }
}

final savedPropertiesProvider =
    AsyncNotifierProvider<SavedPropertiesNotifier, List<PropertyModel>>(() {
  return SavedPropertiesNotifier();
});

final sortedSavedPropertiesProvider = Provider<List<PropertyModel>>((ref) {
  final savedState = ref.watch(savedPropertiesProvider);
  final sortOption = ref.watch(savedSortOptionProvider);
  final mapProps = ref.watch(mapPropertiesProvider).properties;

  if (!savedState.hasValue) return [];
  
  final list = savedState.value!.map((saved) {
    if (saved.imageUrls.isEmpty) {
      final match = mapProps.firstWhere(
        (p) => p.id == saved.id && p.imageUrls.isNotEmpty,
        orElse: () => saved,
      );
      if (match.imageUrls.isNotEmpty) {
        return saved.copyWith(imageUrls: match.imageUrls);
      }
    }
    return saved;
  }).toList();

  switch (sortOption) {
    case SortOption.propertyForYou:
      return list;
    case SortOption.recentlyPosted:
    case SortOption.newest:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    case SortOption.priceHighToLow:
      list.sort((a, b) => b.price.compareTo(a.price));
      return list;
    case SortOption.priceLowToHigh:
      list.sort((a, b) => a.price.compareTo(b.price));
      return list;
  }
});
