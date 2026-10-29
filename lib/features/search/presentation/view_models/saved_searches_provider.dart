import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/property/data/models/map_property_filter.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/search/data/models/saved_search.dart';
import 'package:tilomnov/features/search/data/saved_search_repository.dart';

final savedSearchRepositoryProvider = Provider<SavedSearchRepository>((ref) {
  return SavedSearchRepository(ref.watch(apiClientProvider));
});

/// Why saving a search did not happen.
enum SaveSearchFailure { limitReached, failed }

/// The signed-in user's saved searches, newest first, and every change to
/// them. A change is shown at once and put back when the server refuses.
class SavedSearchesNotifier extends AsyncNotifier<List<SavedSearch>> {
  @override
  Future<List<SavedSearch>> build() {
    ref.watch(isSignedInProvider);
    return ref.watch(savedSearchRepositoryProvider).fetchAll();
  }

  SavedSearchRepository get _repository =>
      ref.read(savedSearchRepositoryProvider);

  /// Null when saved.
  Future<SaveSearchFailure?> save({
    required String name,
    required MapBounds area,
    required MapPropertyFilter filter,
  }) async {
    try {
      final saved = await _repository.save(
        name: name,
        area: area,
        filter: filter,
      );
      final known = state.valueOrNull;
      if (known != null) state = AsyncData([saved, ...known]);
      return null;
    } on SavedSearchLimitReached {
      return SaveSearchFailure.limitReached;
    } catch (e) {
      AppLogger.error('Saving a search failed', e);
      return SaveSearchFailure.failed;
    }
  }

  /// True when the server took it.
  Future<bool> setAlerts(SavedSearch search, bool alerts) =>
      _change(search, search.copyWith(alerts: alerts), alerts: alerts);

  Future<bool> rename(SavedSearch search, String name) =>
      _change(search, search.copyWith(name: name), name: name);

  Future<bool> delete(SavedSearch search) async {
    final before = state.valueOrNull;
    if (before == null) return false;
    state = AsyncData([
      for (final s in before)
        if (s.id != search.id) s,
    ]);
    try {
      await _repository.delete(search.id);
      return true;
    } catch (e) {
      AppLogger.error('Deleting a saved search failed', e);
      state = AsyncData(before);
      return false;
    }
  }

  Future<bool> _change(
    SavedSearch search,
    SavedSearch expected, {
    String? name,
    bool? alerts,
  }) async {
    final before = state.valueOrNull;
    if (before == null) return false;
    state = AsyncData(_replaced(before, expected));
    try {
      final after = await _repository.update(
        search.id,
        name: name,
        alerts: alerts,
      );
      state = AsyncData(_replaced(state.valueOrNull ?? before, after));
      return true;
    } catch (e) {
      AppLogger.error('Changing a saved search failed', e);
      state = AsyncData(before);
      return false;
    }
  }

  static List<SavedSearch> _replaced(
    List<SavedSearch> list,
    SavedSearch search,
  ) => [for (final s in list) s.id == search.id ? search : s];
}

final savedSearchesProvider =
    AsyncNotifierProvider<SavedSearchesNotifier, List<SavedSearch>>(
      SavedSearchesNotifier.new,
    );

/// A saved search to show on the map: the map takes its area and filter,
/// then sets this back to null.
final savedSearchToOpenProvider = StateProvider<SavedSearch?>((ref) => null);
