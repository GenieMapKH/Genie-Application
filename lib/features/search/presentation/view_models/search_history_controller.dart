import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/search/data/models/search_history_entry.dart';
import 'package:genie/features/search/data/search_text.dart';
import 'package:genie/features/search/presentation/view_models/search_providers.dart';

/// The signed-in user's recent searches, loaded afresh each time the search
/// page opens so a search made on another device shows up. Empty for guests.
///
/// Changes show at once and are then sent to the server.
class SearchHistoryController
    extends AutoDisposeAsyncNotifier<List<SearchHistoryEntry>> {
  /// Picking a result closes the page, and with it this controller, while
  /// the search is still being saved: the save goes on, the list is let be.
  bool _disposed = false;

  static const _pendingPrefix = 'pending:';

  @override
  Future<List<SearchHistoryEntry>> build() async {
    ref.onDispose(() => _disposed = true);
    if (!await ref.read(searchHasSessionProvider)()) return const [];
    return ref.read(searchHistoryRepositoryProvider).list();
  }

  /// Called when a search is finished: a result picked, or the search key
  /// pressed. The same text searched before moves to the top.
  Future<void> record(String rawText) async {
    final text = rawText.trim();
    final normalized = SearchText.normalize(text);
    if (!SearchText.isSearchable(normalized)) return;
    // Read now: after the first await the page may be gone, and `ref` with it.
    final repository = ref.read(searchHistoryRepositoryProvider);
    final hasSession = ref.read(searchHasSessionProvider);
    if (!await hasSession()) return;

    final placeholder = SearchHistoryEntry(
      id: '$_pendingPrefix$normalized',
      query: text,
      searchedAt: DateTime.now(),
    );
    _replace(normalized, placeholder);

    try {
      final saved = await repository.record(text);
      _replace(normalized, saved);
    } catch (error, stack) {
      // The search itself worked; only remembering it failed. The next
      // visit loads the list from the server again.
      AppLogger.error('Saving the search to history failed', error, stack);
    }
  }

  /// Rethrows when the server refused, after putting the entry back, so the
  /// page can say so.
  Future<void> remove(SearchHistoryEntry entry) async {
    // Still being saved: it has no id the server knows yet.
    if (entry.id.startsWith(_pendingPrefix)) return;
    final before = state.valueOrNull ?? const <SearchHistoryEntry>[];
    state = AsyncData([
      for (final item in before)
        if (item.id != entry.id) item,
    ]);

    try {
      await ref.read(searchHistoryRepositoryProvider).remove(entry.id);
    } catch (_) {
      if (!_disposed) state = AsyncData(before);
      rethrow;
    }
  }

  /// [entry] first, without the older entry for the same text.
  void _replace(String normalized, SearchHistoryEntry entry) {
    if (_disposed) return;
    final current = state.valueOrNull ?? const <SearchHistoryEntry>[];
    state = AsyncData([
      entry,
      for (final item in current)
        if (SearchText.normalize(item.query) != normalized) item,
    ]);
  }
}

final searchHistoryControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      SearchHistoryController,
      List<SearchHistoryEntry>
    >(SearchHistoryController.new);
