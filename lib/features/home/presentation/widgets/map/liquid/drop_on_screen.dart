import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'package:genie/features/home/utils/map/cluster_transition.dart';
import 'package:genie/features/home/utils/map/markers/property_markers.dart';

/// One drop as drawn this frame.
///
/// [center], [radius], [ring] and [cohesion] are the round drop the necks
/// join. [outline] is its shape on screen (a circle, a price tag, or between
/// the two) and [border] the white band inside that outline.
typedef DropOnScreen = ({
  Offset center,
  double radius,
  double ring,
  double cohesion,
  RRect outline,
  double border,
  Color color,
  double shadow,
  double tagness,
});

/// [drop] at linear progress [p], its map position drawn at [point].
DropOnScreen dropOnScreen(LiquidDrop drop, double p, Offset point) {
  final center = point - Offset(0, drop.liftAt(p));
  final radius = drop.radiusAt(p);
  final ring = drop.ringAt(p);
  final tag = drop.tag;
  final tagness = tag == null ? 0.0 : drop.tagnessAt(p);

  var halfWidth = radius;
  var halfHeight = radius;
  var corner = radius;
  var border = ring;
  var color = PropertyMarkers.green;
  if (tag != null && tagness > 0) {
    // The tag's white border is centred on its body's edge.
    final grow = tag.borderWidth / 2;
    halfWidth = lerpDouble(radius, tag.size.width / 2 + grow, tagness)!;
    halfHeight = lerpDouble(radius, tag.size.height / 2 + grow, tagness)!;
    corner = math.min(
      lerpDouble(radius, tag.radius.x + grow, tagness)!,
      math.min(halfWidth, halfHeight),
    );
    border = lerpDouble(ring, tag.borderWidth, tagness)!;
    // The colour changes once the necks have let go, so none shows green.
    color = _lerpByHue(
      color,
      tag.background,
      const Interval(0.3, 1).transform(tagness),
    );
  }

  return (
    center: center,
    radius: radius,
    ring: ring,
    // A drop turning into a tag lets go of its neighbours first.
    cohesion: 1 - const Interval(0, 0.4).transform(tagness),
    outline: RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: halfWidth * 2,
        height: halfHeight * 2,
      ),
      Radius.circular(corner),
    ),
    border: border,
    color: color,
    // Price tags have no shadow.
    shadow: 1 - tagness,
    tagness: tagness,
  );
}

/// Blends [a] into [b] round the shorter way of the colour wheel, so green
/// turns red through yellow, never through a muddy brown or through blue.
Color _lerpByHue(Color a, Color b, double t) {
  final from = HSVColor.fromColor(a);
  final to = HSVColor.fromColor(b);
  var toHue = to.hue;
  if (toHue - from.hue > 180) toHue -= 360;
  if (from.hue - toHue > 180) toHue += 360;
  return HSVColor.fromAHSV(
    lerpDouble(from.alpha, to.alpha, t)!,
    lerpDouble(from.hue, toHue, t)! % 360,
    lerpDouble(from.saturation, to.saturation, t)!,
    lerpDouble(from.value, to.value, t)!,
  ).toColor();
}
