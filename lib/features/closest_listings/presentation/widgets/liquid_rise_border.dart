import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:tilomnov/features/closest_listings/presentation/closest_liquid_shape.dart';

/// The outline of the pull-up list as it is pulled out of its glass handle:
/// a drop of the panel hangs from the handle and stands on the panel's foot
/// (the glass nav capsule, when the panel's foot is behind it), and widens
/// as it rises until it is the whole panel with its rounded top corners.
/// It follows the pull the way the system's back gesture swells out of the
/// screen's edge.
class LiquidRiseBorder extends ShapeBorder {
  /// 0 resting, 1 once the drop has become the whole panel. At 0 the
  /// outline is the whole panel too (the panel is unseen then, but its
  /// handle still takes touches).
  final double rise;

  final double radius;

  /// Height of the panel's foot hidden behind the glass nav capsule, 0 when
  /// it is not. The foot is rounded like the capsule, so the panel and the
  /// capsule read as one shape; resting, it is exactly the capsule.
  final double footHeight;

  final BorderSide side;

  const LiquidRiseBorder({
    required this.rise,
    this.radius = 22,
    this.footHeight = 0,
    this.side = BorderSide.none,
  });

  /// Half the drop's width at its foot when it first swells: a little
  /// wider than the glass handle.
  static const _footHalfWidth = 70.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final corner = Radius.circular(radius);
    final footCorner = Radius.circular(footHeight / 2);
    final panel = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: corner,
          topRight: corner,
          bottomLeft: footCorner,
          bottomRight: footCorner,
        ),
      );
    if (rise <= 0 || rise >= 1) return panel;

    final t = ClosestLiquidShape.progress(rise);
    final head = ClosestLiquidShape.handle(
      t,
      rect.width,
      radius,
    ).shift(rect.topLeft);
    // The drop hangs from the handle's middle, as wide there as the
    // handle's flat underside, so the handle caps it; risen, it reaches the
    // top with the handle.
    final neckY = lerpDouble(head.center.dy, rect.top, t)!;
    final neck = math.max(0.0, head.width / 2 - head.blRadiusX);
    final footY = rect.bottom - footHeight;
    // The drop's sides stand on the foot, then lift with the pull.
    final shoulder = lerpDouble(footY, neckY, t)!;
    final spread = math.max(neck, lerpDouble(_footHalfWidth, rect.width, t)!);
    final x = rect.center.dx;
    final bend = (spread + neck) / 2;
    final drop = Path()
      ..moveTo(x - spread, shoulder)
      ..cubicTo(x - bend, shoulder, x - bend, neckY, x - neck, neckY)
      ..lineTo(x + neck, neckY)
      ..cubicTo(x + bend, neckY, x + bend, shoulder, x + spread, shoulder)
      ..close();
    // Under the drop's sides: the foot, rounded like the capsule at first
    // and squaring into the panel's sides as it rises, by the time the
    // drop's sides reach them (else its corners notch the sides).
    final shoulderCorner = Radius.circular(
      math.min(
        lerpDouble(footHeight / 2, 0, t)!,
        math.max(0.0, rect.width / 2 - spread),
      ),
    );
    final body = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          rect.left,
          shoulder,
          rect.right,
          rect.bottom,
          topLeft: shoulderCorner,
          topRight: shoulderCorner,
          bottomLeft: footCorner,
          bottomRight: footCorner,
        ),
      );
    return Path.combine(
      PathOperation.intersect,
      Path.combine(PathOperation.union, drop, body),
      panel,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) => LiquidRiseBorder(
    rise: rise,
    radius: radius * t,
    footHeight: footHeight * t,
    side: side.scale(t),
  );

  @override
  bool operator ==(Object other) =>
      other is LiquidRiseBorder &&
      other.rise == rise &&
      other.radius == radius &&
      other.footHeight == footHeight &&
      other.side == side;

  @override
  int get hashCode => Object.hash(rise, radius, footHeight, side);
}
