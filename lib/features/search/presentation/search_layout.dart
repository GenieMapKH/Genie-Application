import 'dart:math' as math;

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

  /// A listing card column in a sheet over the map never gets narrower than
  /// this: below it the price and details no longer fit, so the sheet keeps
  /// fewer, wider columns.
  static const double minCardColumnWidth = 300;

  /// Space between listing cards in a sheet over the map, both ways.
  static const double cardSpacing = 16;

  /// Listing card columns in a sheet [sheetWidth] wide.
  static int cardColumns(double sheetWidth) {
    final content = sheetWidth - 2 * gutter(sheetWidth);
    return math.max(
      1,
      ((content + cardSpacing) / (minCardColumnWidth + cardSpacing)).floor(),
    );
  }

  /// Width of one listing card column in a sheet [sheetWidth] wide.
  static double cardColumnWidth(double sheetWidth) {
    final count = cardColumns(sheetWidth);
    final content = sheetWidth - 2 * gutter(sheetWidth);
    return (content - cardSpacing * (count - 1)) / count;
  }

  /// Height of a listing card [columnWidth] wide: a photo about two thirds
  /// as tall as it is wide, above the price and details. On a short sheet (a
  /// phone held sideways) it shrinks so a whole card still fits.
  static double cardHeight(double columnWidth, {required double sheetHeight}) {
    final natural = (columnWidth * 0.72).clamp(240.0, 340.0);
    return math.min(natural, math.max(180.0, sheetHeight * 0.62));
  }
}
