/// Sizes that adapt search to the screen: phones get full-width lists and a
/// bottom sheet, tablets a centred column and a side panel beside the map.
abstract final class SearchLayout {
  /// From this width on (a small tablet, or a large phone held sideways) the
  /// map is wide enough to keep a list beside it instead of under it.
  static const double wideBreakpoint = 720;

  /// Result rows stop growing past this; wider screens centre them.
  static const double contentMaxWidth = 680;

  static bool isWide(double width) => width >= wideBreakpoint;

  /// Width of the results panel beside the map on wide screens.
  static double sidePanelWidth(double screenWidth) =>
      (screenWidth * 0.4).clamp(340.0, 420.0);

  /// Height the results sheet rests at on phones: enough for a few rows,
  /// while most of the map stays visible.
  static double sheetRestingHeight(double availableHeight) =>
      (availableHeight * 0.36).clamp(240.0, 380.0);

  /// Horizontal padding of list rows: roomier on wider screens.
  static double gutter(double width) => width >= 600 ? 24 : 16;
}
