import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bars of how many listings ask each price, lit inside the chosen range.
/// Bar `i` covers the `i`-th equal share of the slider's span.
class PriceHistogram extends StatelessWidget {
  final List<int> counts;

  /// The chosen range as shares (0 to 1) of the slider's span.
  final double from;
  final double to;

  final Color litColor;
  final Color dimColor;

  const PriceHistogram({
    super.key,
    required this.counts,
    required this.from,
    required this.to,
    required this.litColor,
    required this.dimColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _HistogramPainter(counts, from, to, litColor, dimColor),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  final List<int> counts;
  final double from;
  final double to;
  final Color lit;
  final Color dim;

  _HistogramPainter(this.counts, this.from, this.to, this.lit, this.dim);

  static const _gapShare = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final highest = counts.reduce(math.max);
    if (highest == 0) return;

    final slot = size.width / counts.length;
    final width = slot * (1 - _gapShare);
    final paint = Paint();
    for (var i = 0; i < counts.length; i++) {
      if (counts[i] == 0) continue;
      final middle = (i + 0.5) / counts.length;
      paint.color = middle >= from && middle <= to ? lit : dim;
      // Even one listing shows: a bar is never shorter than its width.
      final height = math.max(size.height * counts[i] / highest, width);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * slot + (slot - width) / 2,
            size.height - height,
            width,
            height,
          ),
          Radius.circular(width / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HistogramPainter old) =>
      old.counts != counts ||
      old.from != from ||
      old.to != to ||
      old.lit != lit ||
      old.dim != dim;
}
