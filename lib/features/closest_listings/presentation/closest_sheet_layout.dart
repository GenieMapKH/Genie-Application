import 'dart:math' as math;

import 'package:tilomnov/features/search/presentation/search_layout.dart';

/// Sizes of the map's pull-up list for any screen: a full-width sheet on
/// phones, a panel docked at the left on tablets and phones held sideways
/// (the map's buttons are on the right), cards in as many columns as fit.
abstract final class ClosestSheetLayout {
  /// What shows of the sheet while it rests: its handle.
  static const double peekHeight = 40;

  /// Gap between the docked panel and the screen's left edge.
  static const double dockMargin = 12;

  /// A card column never gets narrower than this: below it the price and
  /// details no longer fit, so the sheet keeps fewer, wider columns.
  static const double minColumnWidth = 300;

  /// Space between cards, both ways.
  static const double spacing = 16;

  /// Whether the sheet is a panel at the left rather than full width.
  static bool isDocked(double screenWidth) => SearchLayout.isWide(screenWidth);

  /// The sheet's width on a screen [screenWidth] wide.
  static double width(double screenWidth) => isDocked(screenWidth)
      ? SearchLayout.sidePanelWidth(screenWidth)
      : screenWidth;

  /// Space left and right of the cards inside a sheet [sheetWidth] wide.
  static double gutter(double sheetWidth) => SearchLayout.gutter(sheetWidth);

  /// Card columns in a sheet [sheetWidth] wide.
  static int columns(double sheetWidth) {
    final content = sheetWidth - 2 * gutter(sheetWidth);
    return math.max(
      1,
      ((content + spacing) / (minColumnWidth + spacing)).floor(),
    );
  }

  /// Width of one card column in a sheet [sheetWidth] wide.
  static double columnWidth(double sheetWidth) {
    final count = columns(sheetWidth);
    final content = sheetWidth - 2 * gutter(sheetWidth);
    return (content - spacing * (count - 1)) / count;
  }

  /// Height of a card [columnWidth] wide: a photo about two thirds as tall
  /// as it is wide, above the price and details. On a short sheet (a phone
  /// held sideways) it shrinks so a whole card still fits under the header.
  static double cardHeight(double columnWidth, {required double sheetHeight}) {
    final natural = (columnWidth * 0.72).clamp(240.0, 340.0);
    return math.min(natural, math.max(180.0, sheetHeight * 0.62));
  }

  /// The middle resting place, as a share of [availableHeight]: about half,
  /// but never so low that a card does not show.
  static double middleExtent(double availableHeight) =>
      math.max(0.5, math.min(1.0, 320 / availableHeight));

  /// The resting share of [availableHeight]: just the handle, above a
  /// [foot] hidden behind the nav.
  static double peekExtent(double availableHeight, {double foot = 0}) =>
      math.min(1.0, (peekHeight + foot) / availableHeight);

  /// How far, as a share of the way to the next stop, a released sheet must
  /// have travelled in its direction to carry on to it. The built-in snap
  /// picks the nearest stop, which sent a slow, half-hearted pull from the
  /// bottom back down; this commits to the direction the finger went.
  static const double commitShare = 0.2;

  /// A released sheet is judged from where its speed would take it in this
  /// many seconds: a flick reaches past the next stop, a slow pull does not.
  static const double releaseProjection = 0.12;

  /// How far, in logical pixels, the glass handle is pulled before the drop
  /// swelling out of it has become the whole panel.
  static const double liquidRiseDistance = 140;

  /// The stop (an extent, from [stops] in ascending order) a sheet released
  /// at [extent] comes to rest at, having last moved up or down.
  static double settleExtent(
    double extent,
    List<double> stops, {
    required bool movingUp,
  }) {
    final below = stops.lastWhere(
      (s) => s <= extent,
      orElse: () => stops.first,
    );
    final above = stops.firstWhere(
      (s) => s >= extent,
      orElse: () => stops.last,
    );
    if (below == above) return below;
    final share = (extent - below) / (above - below);
    return movingUp
        ? (share < commitShare ? below : above)
        : (share > 1 - commitShare ? above : below);
  }
}
