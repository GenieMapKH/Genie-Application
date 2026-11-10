import 'package:flutter/material.dart';

import 'package:tilomnov/features/home/utils/map/cluster_label.dart';

/// Paints the counts on bubbles and the prices on tags during a cluster
/// transition, each at its own opacity ([ClusterLabel.opacityAt]).
abstract final class LiquidLabels {
  /// Laid out once per count, not every frame of every transition.
  static final _counts = <String, TextPainter>{};

  /// Paints [labels] at linear progress [p], each centred on [centerOf].
  static void paint(
    Canvas canvas,
    List<ClusterLabel> labels,
    double p,
    Offset Function(ClusterLabel label) centerOf,
  ) {
    // Labels fading alike share one layer.
    final byOpacity = <double, List<ClusterLabel>>{};
    for (final label in labels) {
      final opacity = label.opacityAt(p);
      if (opacity > 0) (byOpacity[opacity] ??= []).add(label);
    }
    for (final MapEntry(key: opacity, value: group) in byOpacity.entries) {
      _faded(canvas, opacity, () {
        for (final label in group) {
          _paintOne(canvas, label, centerOf(label));
        }
      });
    }
  }

  static void _paintOne(Canvas canvas, ClusterLabel label, Offset center) {
    final tag = label.spot.tag;
    if (tag != null) {
      tag.paintLabels(
        canvas,
        center - Offset(tag.size.width / 2, tag.size.height / 2),
      );
      return;
    }
    final count = _countOf(label.spot.count);
    count.paint(canvas, center - Offset(count.width / 2, count.height / 2));
  }

  /// Runs [paint] at [opacity].
  static void _faded(Canvas canvas, double opacity, VoidCallback paint) {
    if (opacity >= 1) return paint();
    canvas.saveLayer(
      null,
      Paint()..color = Colors.black.withValues(alpha: opacity),
    );
    paint();
    canvas.restore();
  }

  static TextPainter _countOf(int count) {
    final text = count > 999 ? '999+' : '$count';
    return _counts[text] ??= TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
