/// A text the signed-in user searched; the same list on every device.
class SearchHistoryEntry {
  final String id;

  /// As it was typed.
  final String query;
  final DateTime searchedAt;

  const SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.searchedAt,
  });

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      id: json['id'] as String,
      query: json['query'] as String,
      searchedAt: DateTime.parse(json['searchedAt'] as String),
    );
  }
}
