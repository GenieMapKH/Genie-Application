import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The point below a price tag that sits on the listing, so the tag reads
/// as a map pin.
///
/// Shared by the map marker and the merge animation, so both draw the very
/// same pin.
abstract final class PriceTagPin {
  /// How far the point reaches below the tag's outer edge.
  static const tail = 6.0;

  /// Half the point's width for each unit of its length.
  static const _slope = 0.8;

  /// The point starts this far inside the tag so the two join seamlessly.
  static const _overlap = 2.0;

  /// How much shorter the coloured point is than the white one around it,
  /// per unit of border, so the white band keeps one width along its sides.
  static final _tipInset = math.sqrt(1 + _slope * _slope) / _slope - 1;

  /// Paints [outline] and a point [tail] long below its middle with [paint].
  static void paintShape(
    Canvas canvas,
    RRect outline,
    double tail,
    Paint paint,
  ) {
    canvas.drawRRect(outline, paint);
    if (tail <= 0) return;

    final x = outline.center.dx;
    final base = outline.bottom - _overlap;
    final halfWidth = (tail + _overlap) * _slope;
    canvas.drawPath(
      Path()
        ..moveTo(x - halfWidth, base)
        ..lineTo(x + halfWidth, base)
        ..lineTo(x, outline.bottom + tail)
        ..close(),
      paint,
    );
  }

  /// Paints a tag of [color] inside a white band [border] wide, its outer
  /// edge [outline] and its point [tail] long.
  static void paint(
    Canvas canvas,
    RRect outline,
    double tail,
    double border,
    Color color,
  ) {
    paintShape(canvas, outline, tail, Paint()..color = const Color(0xFFFFFFFF));
    paintShape(
      canvas,
      outline.deflate(border),
      math.max(0, tail - border * _tipInset),
      Paint()..color = color,
    );
  }
}
