import 'dart:math';

import 'package:flutter/widgets.dart';

/// Sizes that adapt the Saved and My Properties lists to the screen: phones
/// keep their layout, tablets lay cards out in as many columns as fit so a
/// lone card stays card-sized instead of stretching across the screen.
abstract final class PropertyListLayout {
  /// A tablet in either orientation; a phone held sideways stays below it.
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  /// Widest a Saved card grows on tablets before another column is added.
  static const double savedCardMaxWidth = 260;

  /// Widest a My Properties card grows on tablets before another column is
  /// added; wider than a Saved card so its stats row stays readable.
  static const double ownCardMaxWidth = 360;

  /// Gap between cards side by side.
  static const double columnSpacing = 16;

  /// Keep compact cards readable on narrow phones and with enlarged text.
  static int compactColumns(BuildContext context, double width) => max(
    1,
    ((width + 12) /
            (148 * MediaQuery.textScalerOf(context).scale(12) / 12 + 12))
        .floor(),
  );

  /// Columns of at most [maxCardWidth] that fill [width], like
  /// [SliverGridDelegateWithMaxCrossAxisExtent].
  static int columnCount(double width, double maxCardWidth) =>
      max(1, ((width + columnSpacing) / (maxCardWidth + columnSpacing)).ceil());
}
