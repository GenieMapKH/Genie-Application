/// The rules a search text follows, the same as the server's: what counts as
/// the same text, and when a text is long enough to be worth a request.
abstract final class SearchText {
  /// Shorter texts match too much to be useful.
  static const minLength = 2;

  /// The server cuts longer texts; the field stops there too.
  static const maxLength = 80;

  static final _spaces = RegExp(r'\s+');
  static final _wildcards = RegExp(r'[%_\\]');

  /// Lowercase, single spaces, no LIKE wildcards: "  Veng  SRENG " and
  /// "veng sreng" are one search, sent and cached once.
  static String normalize(String raw) {
    final text = raw
        .toLowerCase()
        .replaceAll(_wildcards, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
    return text.length > maxLength ? text.substring(0, maxLength).trim() : text;
  }

  static bool isSearchable(String normalized) => normalized.length >= minLength;
}
