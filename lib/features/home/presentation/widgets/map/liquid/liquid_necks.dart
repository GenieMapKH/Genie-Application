import 'dart:math' as math;
import 'dart:ui';

import 'package:genie/features/home/presentation/widgets/map/liquid/drop_on_screen.dart';

/// The necks joining drops close enough to pull on each other, drawn as
/// plain paths so their edges stay as crisp as the map's own dots.
///
/// [core] joins the green insides of the drops and [rim] their white rings;
/// both are filled together with the drops' own circles. A drop with less
/// [DropOnScreen.cohesion] holds on more weakly, and not at all at 0.
abstract final class LiquidNecks {
  /// How far apart, as a share of the smaller drop's green radius, two drops
  /// still hold on to each other. The neck thins out to nothing at this gap.
  static const reach = 1.0;

  /// How much wider than its waist a neck is where it meets a drop, from 0
  /// (straight thread) to 1 (wraps over the drop's top).
  static const _spread = 0.5;

  /// The rim is never wider than this share of the smaller radius, so it
  /// stays a neck and does not swallow a drop.
  static const _maxWaist = 0.98;

  /// A green neck thinner than this (half width, in logical pixels) would
  /// show as a grey hairline, so it is left out.
  static const _minWaist = 0.3;

  /// Where circles overlap, how far past their crease the neck reaches,
  /// as a share of the room left, so no notch shows at the crease.
  static const _creaseFill = 0.35;

  static ({Path core, Path rim}) joining(List<DropOnScreen> drops) {
    final core = Path();
    final rim = Path();
    if (drops.length < 2) return (core: core, rim: rim);

    final sorted = [...drops]
      ..sort((a, b) => a.center.dx.compareTo(b.center.dx));
    final largest = sorted.map(_coreRadius).reduce(math.max);
    final farthest = largest * (2 + reach);

    for (var i = 0; i < sorted.length; i++) {
      final a = sorted[i];
      for (var j = i + 1; j < sorted.length; j++) {
        final b = sorted[j];
        if (b.center.dx - a.center.dx >= farthest) break;
        if ((b.center.dy - a.center.dy).abs() >= farthest) continue;
        _join(a, b, core: core, rim: rim);
      }
    }
    return (core: core, rim: rim);
  }

  static double _coreRadius(DropOnScreen drop) => drop.radius - drop.ring;

  static void _join(
    DropOnScreen a,
    DropOnScreen b, {
    required Path core,
    required Path rim,
  }) {
    final coreA = _coreRadius(a);
    final coreB = _coreRadius(b);
    final smaller = math.min(coreA, coreB);
    final distance = (b.center - a.center).distance;
    final gap = distance - coreA - coreB;
    final cohesion = math.min(a.cohesion, b.cohesion);
    if (smaller <= 0 || cohesion <= 0 || gap >= smaller * reach) return;

    // 0 where the neck snaps, 1 once the drops touch.
    final pull = _smoothstep((1 - gap / (smaller * reach)).clamp(0.0, 1.0));
    // Touching drops share a neck half as thick as the smaller one; pressed
    // together they fill out into one.
    final coreWaist = gap >= 0
        ? smaller * 0.5 * pull
        : smaller * (0.5 + 0.5 * math.min(-gap / smaller, 1.0));
    if (coreWaist * cohesion < _minWaist) return;
    // The white ring hugs the green neck, and grows in with it.
    final ring = (a.ring + b.ring) / 2;
    final rimWaist = coreWaist + math.min(ring, coreWaist);
    final spread = _spread * pull;

    _addNeck(
      core,
      a.center,
      coreA,
      b.center,
      coreB,
      coreWaist,
      spread,
      cohesion,
    );
    _addNeck(
      rim,
      a.center,
      a.radius,
      b.center,
      b.radius,
      rimWaist,
      spread,
      cohesion,
    );
  }

  /// Adds the neck between two circles to [path]: from each circle it
  /// follows the circle's own curve, then narrows to [waist] (half its
  /// width) midway. With [cohesion] below 1 it thins by that much, and is
  /// left out once it would no longer fill the crease of overlapping
  /// circles.
  static void _addNeck(
    Path path,
    Offset c1,
    double r1,
    Offset c2,
    double r2,
    double waist,
    double spread,
    double cohesion,
  ) {
    final axis = c2 - c1;
    final d = axis.distance;
    // One circle inside the other: nothing to join.
    if (d <= (r1 - r2).abs() + 0.01) return;

    // Where overlapping circles cross, the neck must at least fill the crease.
    final crossAt = (d * d + r1 * r1 - r2 * r2) / (2 * d);
    final crossing = d < r1 + r2
        ? math.sqrt(math.max(0.0, r1 * r1 - crossAt * crossAt))
        : 0.0;
    final widest = _maxWaist * math.min(r1, r2);
    final crease = crossing > 0
        ? crossing + (widest - crossing) * _creaseFill
        : 0.0;
    final w = math.max(crease, math.min(waist, widest)) * cohesion;
    // Narrower than the crease, it would no longer meet both circles.
    if (w < crossing || w <= 0) return;

    // Where the neck leaves each circle: x along the axis from c1, h away
    // from it.
    final h1 = w + (r1 - w) * spread * cohesion;
    final h2 = w + (r2 - w) * spread * cohesion;
    final e1 = math.sqrt(math.max(0.0, r1 * r1 - h1 * h1));
    final e2 = math.sqrt(math.max(0.0, r2 * r2 - h2 * h2));
    final x1 = e1;
    final x2 = d - e2;
    final xm = (x1 + x2) / 2;
    final len1 = xm - x1;
    final len2 = x2 - xm;

    // Leave along the circle's tangent, but never dip below the waist.
    final k1 = math.min(0.6 * len1, (h1 - w) * r1 / math.max(e1, 1e-6));
    final k2 = math.min(0.6 * len2, (h2 - w) * r2 / math.max(e2, 1e-6));
    final out1 = Offset(x1 + k1 * h1 / r1, h1 - k1 * e1 / r1);
    final out2 = Offset(x2 - k2 * h2 / r2, h2 - k2 * e2 / r2);

    final u = axis / d;
    final n = Offset(-u.dy, u.dx);
    Offset at(double x, double h) => c1 + u * x + n * h;

    path
      ..moveTo(at(x1, h1).dx, at(x1, h1).dy)
      .._cubic(at(out1.dx, out1.dy), at(xm - len1 / 2, w), at(xm, w))
      .._cubic(at(xm + len2 / 2, w), at(out2.dx, out2.dy), at(x2, h2))
      ..lineTo(at(x2, -h2).dx, at(x2, -h2).dy)
      .._cubic(at(out2.dx, -out2.dy), at(xm + len2 / 2, -w), at(xm, -w))
      .._cubic(at(xm - len1 / 2, -w), at(out1.dx, -out1.dy), at(x1, -h1))
      ..close();
  }

  static double _smoothstep(double x) => x * x * (3 - 2 * x);
}

extension on Path {
  void _cubic(Offset c1, Offset c2, Offset end) =>
      cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
}
