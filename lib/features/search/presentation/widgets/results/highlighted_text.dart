import 'package:flutter/material.dart';

/// [text] with every occurrence of the searched words drawn in [matchStyle],
/// so the eye finds why a row matched, as in a map app's suggestions.
class HighlightedText extends StatelessWidget {
  final String text;

  /// The normalized search text; matching ignores case.
  final String query;
  final TextStyle style;
  final TextStyle matchStyle;
  final int maxLines;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    required this.matchStyle,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _spans()),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<TextSpan> _spans() {
    final ranges = matchRanges(text, query);
    if (ranges.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final (start, end) in ranges) {
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }
      spans.add(TextSpan(text: text.substring(start, end), style: matchStyle));
      cursor = end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return spans;
  }

  /// Sorted, non-overlapping `(start, end)` ranges of [text] that match a
  /// word of [query].
  @visibleForTesting
  static List<(int, int)> matchRanges(String text, String query) {
    final lower = text.toLowerCase();
    final words = query.split(' ').where((word) => word.isNotEmpty);

    final found = <(int, int)>[];
    for (final word in words) {
      var from = 0;
      while (true) {
        final index = lower.indexOf(word, from);
        if (index < 0) break;
        found.add((index, index + word.length));
        from = index + word.length;
      }
    }
    if (found.isEmpty) return const [];

    found.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[found.first];
    for (final range in found.skip(1)) {
      final last = merged.last;
      if (range.$1 <= last.$2) {
        merged[merged.length - 1] = (
          last.$1,
          range.$2 > last.$2 ? range.$2 : last.$2,
        );
      } else {
        merged.add(range);
      }
    }
    return merged;
  }
}
