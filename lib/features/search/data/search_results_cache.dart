import 'package:tilomnov/features/search/data/models/search_results.dart';

/// Recent answers, so deleting a letter or reopening the search shows them at
/// once instead of asking the server again. Least recently used goes first.
class SearchResultsCache {
  final int maxEntries;
  final Duration timeToLive;
  final DateTime Function() _now;

  SearchResultsCache({
    this.maxEntries = 40,
    this.timeToLive = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Insertion-ordered (a Dart map literal is a LinkedHashMap), so the
  /// first key is the least recently used one.
  final _entries = <String, (DateTime, SearchResults)>{};

  SearchResults? get(String key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;
    if (_now().difference(entry.$1) > timeToLive) return null;

    _entries[key] = entry; // Most recently used now.
    return entry.$2;
  }

  void put(String key, SearchResults results) {
    _entries.remove(key);
    if (_entries.length >= maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    _entries[key] = (_now(), results);
  }

  void clear() => _entries.clear();
}
