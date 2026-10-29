import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/search/data/models/search_area.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_providers.dart';
import 'package:tilomnov/features/search/presentation/view_models/search_selection.dart';

/// The place or person the map currently shows, and their listings.
class SearchAreaState {
  final SearchTarget target;
  final AsyncValue<SearchArea> area;

  const SearchAreaState(this.target, this.area);
}

/// Null while the map is not showing a search.
class SearchAreaController extends Notifier<SearchAreaState?> {
  /// Bumped on every new target, so a slow answer for an older one is dropped.
  int _generation = 0;

  @override
  SearchAreaState? build() => null;

  Future<void> show(SearchTarget target) async {
    final generation = ++_generation;
    state = SearchAreaState(target, const AsyncLoading());

    final area = await AsyncValue.guard(() => _load(target));
    if (generation != _generation) return;
    state = SearchAreaState(target, area);
  }

  Future<void> retry() async {
    final target = state?.target;
    if (target != null) await show(target);
  }

  void clear() {
    _generation++;
    state = null;
  }

  Future<SearchArea> _load(SearchTarget target) {
    final repository = ref.read(searchRepositoryProvider);
    return switch (target) {
      PlaceTarget() => repository.placeArea(
        target.place,
        language: target.language,
        sessionToken: target.sessionToken,
      ),
      PersonTarget() => repository.publisherArea(target.person),
    };
  }
}

final searchAreaControllerProvider =
    NotifierProvider<SearchAreaController, SearchAreaState?>(
      SearchAreaController.new,
    );
