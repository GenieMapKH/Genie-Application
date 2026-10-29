import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Rounded shapes drawn with continuous corners, as Apple draws its icons,
/// cards and sheets: the curvature eases into the straight edge instead of
/// switching from straight to a circular arc, so the corner has no visible
/// "kink". Devices without Impeller draw an ordinary rounded rectangle.
abstract final class AppShapes {
  /// A continuous-corner rectangle with every corner at [radius].
  static RoundedSuperellipseBorder continuous(
    double radius, {
    BorderSide side = BorderSide.none,
  }) => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side,
  );

  /// A continuous-corner rectangle rounded only along its top edge, for
  /// sheets rising from the bottom of the screen.
  static RoundedSuperellipseBorder continuousTop(double radius) =>
      RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      );

  /// The corner radius of a shape set [inset] inside one with [outer]
  /// corners, so both curves share a centre and the gap between them stays
  /// even all the way round.
  static double concentric(double outer, double inset) =>
      math.max(outer - inset, 0);
}
