import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'package:tilomnov/features/closest_listings/presentation/closest_sheet_layout.dart';

/// Where the glass handle is as the pull-up list is drawn out of it: a pill
/// resting above the nav that stretches, as it is pulled, into the top edge
/// of the panel itself. The drop of the panel hangs from it
/// ([LiquidRiseBorder]) and the handle is drawn there ([ClosestGlassHandle]):
/// one place, so the two stay joined.
abstract final class ClosestLiquidShape {
  /// The handle while the sheet rests.
  static const Size restingHandle = Size(84, 28);

  /// How far the shapes have changed for a pull of [rise], 0 resting to 1
  /// once the panel is whole.
  static double progress(double rise) =>
      Curves.easeInOut.transform(rise.clamp(0.0, 1.0));

  /// The handle at [progress] in a panel [width] wide whose top corners are
  /// [radius]. Its middle stays at the middle of the resting strip, where
  /// the panel's own grip is.
  static RRect handle(double progress, double width, double radius) {
    const strip = ClosestSheetLayout.peekHeight;
    final w = lerpDouble(restingHandle.width, width, progress)!;
    final h = lerpDouble(restingHandle.height, strip, progress)!;
    final top = lerpDouble((strip - restingHandle.height) / 2, 0, progress)!;
    final pill = Radius.circular(restingHandle.height / 2);
    final topCorner = Radius.lerp(pill, Radius.circular(radius), progress)!;
    final bottomCorner = Radius.lerp(pill, Radius.zero, progress)!;
    return RRect.fromLTRBAndCorners(
      (width - w) / 2,
      top,
      (width + w) / 2,
      top + h,
      topLeft: topCorner,
      topRight: topCorner,
      bottomLeft: bottomCorner,
      bottomRight: bottomCorner,
    );
  }
}
