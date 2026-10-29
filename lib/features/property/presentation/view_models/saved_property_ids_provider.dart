import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/property/data/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(apiClientProvider));
});

/// Counts up whenever a listing is back among the saved ones on the server:
/// a save it confirmed, or an unsave it refused. The Saved list then reads it
/// in.
final savedListingsAddedProvider = StateProvider<int>((ref) => 0);

/// The ids of the listings the signed-in user saved, most recently saved
/// first: the heart on every card, and the Saved count. Empty for a guest,
/// whose hearts must not show the previous user's choices.
class SavedPropertyIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final repo = ref.watch(favoritesRepositoryProvider);
    if (!ref.watch(isSignedInProvider)) return {};
    return (await repo.fetchIds()).toSet();
  }

  /// Saves listing [id], or unsaves it when saved: shown at once, undone if
  /// the server refuses. Only for a signed-in user: a guest is asked to sign
  /// in first, since a favourite kept nowhere but on screen would be lost.
  Future<void> toggle(String id) async {
    final current = state.valueOrNull;
    if (!ref.read(isSignedInProvider) || current == null) return;
    final saving = !current.contains(id);
    state = AsyncData(_withSaved(current, id, saving));

    final repo = ref.read(favoritesRepositoryProvider);
    try {
      await (saving ? repo.favorite(id) : repo.unfavorite(id));
      if (saving) _added();
    } catch (e) {
      AppLogger.error(
        saving ? 'Adding a favourite failed' : 'Removing a favourite failed',
        e,
      );
      // Only this listing goes back: others may have changed meanwhile.
      final now = state.valueOrNull;
      if (now != null) state = AsyncData(_withSaved(now, id, !saving));
      if (!saving) _added();
    }
  }

  void _added() => ref.read(savedListingsAddedProvider.notifier).state++;

  /// [ids] with [id] in it, first, or without it.
  static Set<String> _withSaved(Set<String> ids, String id, bool saved) =>
      saved ? {id, ...ids} : ({...ids}..remove(id));
}

final savedPropertyIdsProvider =
    AsyncNotifierProvider<SavedPropertyIdsNotifier, Set<String>>(
      SavedPropertyIdsNotifier.new,
    );

/// Whether the user saved listing [id]: what a heart shows. Rebuilds only
/// that heart when it changes.
final isPropertySavedProvider = Provider.autoDispose.family<bool, String>((
  ref,
  id,
) {
  return ref.watch(
    savedPropertyIdsProvider.select(
      (ids) => ids.valueOrNull?.contains(id) ?? false,
    ),
  );
});
