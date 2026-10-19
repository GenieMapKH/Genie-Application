import 'package:flutter/material.dart';

import 'package:genie/features/home/utils/map/cluster_layout.dart';

/// Paints the counts on bubbles and the prices on tags during a
/// [ClusterTransition], fading out where the drops leave and in where they
/// land.
abstract final class LiquidLabels {
  /// The labels of the markers being left, at linear progress [p]. Prices
  /// go first, before their tag starts to round into a drop.
  static void paintOutgoing(
    Canvas canvas,
    List<ClusterSpot> spots,
    double p,
    Offset Function(ClusterSpot spot) centerOf,
  ) {
    _paint(
      canvas,
      spots,
      countOpacity: 1 - const Interval(0, 0.35).transform(p),
      priceOpacity: 1 - const Interval(0, 0.15).transform(p),
      centerOf: centerOf,
    );
  }

  /// The labels of the markers being formed, at linear progress [p]. Prices
  /// come last, once their tag has taken shape.
  static void paintIncoming(
    Canvas canvas,
    List<ClusterSpot> spots,
    double p,
    Offset Function(ClusterSpot spot) centerOf,
  ) {
    _paint(
      canvas,
      spots,
      countOpacity: const Interval(0.6, 1).transform(p),
      priceOpacity: const Interval(0.8, 1).transform(p),
      centerOf: centerOf,
    );
  }

  static void _paint(
    Canvas canvas,
    List<ClusterSpot> spots, {
    required double countOpacity,
    required double priceOpacity,
    required Offset Function(ClusterSpot spot) centerOf,
  }) {
    _faded(canvas, countOpacity, () {
      for (final spot in spots) {
        if (spot.tag == null) _paintCount(canvas, spot, centerOf(spot));
      }
    });
    _faded(canvas, priceOpacity, () {
      for (final spot in spots) {
        final tag = spot.tag;
        if (tag == null) continue;
        final center = centerOf(spot);
        tag.paintLabels(
          canvas,
          center - Offset(tag.size.width / 2, tag.size.height / 2),
        );
      }
    });
  }

  /// Runs [paint] at [opacity], skipping it when invisible.
  static void _faded(Canvas canvas, double opacity, VoidCallback paint) {
    if (opacity <= 0) return;
    if (opacity >= 1) return paint();
    canvas.saveLayer(
      null,
      Paint()..color = Colors.black.withValues(alpha: opacity),
    );
    paint();
    canvas.restore();
  }

  static void _paintCount(Canvas canvas, ClusterSpot spot, Offset center) {
    final label = TextPainter(
      text: TextSpan(
        text: spot.count > 999 ? '999+' : '${spot.count}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }
}
