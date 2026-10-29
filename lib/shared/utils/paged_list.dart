/// A list read from the server a page at a time: what is loaded so far,
/// whether more is coming, and whether the next page is on its way.
class PagedList<T> {
  final List<T> items;
  final bool hasMore;
  final bool loadingMore;

  const PagedList({
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
  });

  PagedList<T> copyWith({List<T>? items, bool? hasMore, bool? loadingMore}) {
    return PagedList(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  /// The next page, [more], added after the items already loaded. One
  /// already loaded (by [idOf]) is not added again: the list may have
  /// shifted on the server between two pages.
  PagedList<T> appended(
    List<T> more, {
    required bool hasMore,
    required Object Function(T) idOf,
  }) {
    final loaded = {for (final item in items) idOf(item)};
    return PagedList(
      items: [...items, ...more.where((item) => !loaded.contains(idOf(item)))],
      hasMore: hasMore,
    );
  }
}
