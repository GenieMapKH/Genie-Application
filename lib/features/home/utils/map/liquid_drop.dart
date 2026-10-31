import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/utils/map/cluster_layout.dart';
import 'package:tilomnov/features/home/utils/map/markers/price_tag_layout.dart';

/// One listing gliding from the spot that showed it to the one that will.
/// Drops heading for the same spot meet and fuse; drops leaving one spot
/// pull apart. Zooming in to price tags, a drop that has arrived stretches
/// into its [tag]; zooming out, the tag first rounds into a drop.
///
/// Every `...At` method takes the transition's linear progress, 0 to 1.
class LiquidDrop {
  final LatLng from;
  final LatLng to;
  final double fromRadius;
  final double toRadius;
  final double fromRing;
  final double toRing;
  final double fromLift;
  final double toLift;

  /// How much the drop looks like its [tag], at the start and at the end:
  /// 0 is a round drop, 1 the tag.
  final double fromTagness;
  final double toTagness;
  final PriceTagLayout? tag;

  /// How the drops speed up and settle.
  static const curve = Curves.easeInOutCubic;

  const LiquidDrop({
    required this.from,
    required this.to,
    required this.fromRadius,
    required this.toRadius,
    required this.fromRing,
    required this.toRing,
    this.fromLift = 0,
    this.toLift = 0,
    this.fromTagness = 0,
    this.toTagness = 0,
    this.tag,
  });

  LiquidDrop.between(ClusterSpot from, ClusterSpot to)
    : this(
        from: from.position,
        to: to.position,
        fromRadius: from.radius,
        toRadius: to.radius,
        fromRing: from.ring,
        toRing: to.ring,
        fromLift: from.lift,
        toLift: to.lift,
        fromTagness: from.tag == null ? 0 : 1,
        toTagness: to.tag == null ? 0 : 1,
        tag: to.tag ?? from.tag,
      );

  bool get moves =>
      from != to ||
      fromRadius != toRadius ||
      fromRing != toRing ||
      fromTagness != toTagness;

  bool get _becomesTag => toTagness > fromTagness;
  bool get _becomesDrop => toTagness < fromTagness;

  /// Becoming a tag, the drop travels first and then takes shape; becoming
  /// a drop, it first rounds and then travels.
  Interval get _travel => _becomesTag
      ? const Interval(0, 0.7)
      : _becomesDrop
      ? const Interval(0.3, 1)
      : const Interval(0, 1);

  Interval get _reshape =>
      _becomesTag ? const Interval(0.55, 1) : const Interval(0, 0.45);

  double _travelled(double p) => curve.transform(_travel.transform(p));

  LatLng positionAt(double p) {
    final t = _travelled(p);
    return LatLng(
      lerpDouble(from.latitude, to.latitude, t)!,
      lerpDouble(from.longitude, to.longitude, t)!,
    );
  }

  double radiusAt(double p) => lerpDouble(fromRadius, toRadius, _travelled(p))!;

  double ringAt(double p) => lerpDouble(fromRing, toRing, _travelled(p))!;

  double liftAt(double p) => lerpDouble(fromLift, toLift, _travelled(p))!;

  double tagnessAt(double p) => lerpDouble(
    fromTagness,
    toTagness,
    Curves.easeInOut.transform(_reshape.transform(p)),
  )!;

  /// From where and how this drop is at [p] to [spot].
  LiquidDrop redirectedAt(double p, ClusterSpot spot) => LiquidDrop(
    from: positionAt(p),
    to: spot.position,
    fromRadius: radiusAt(p),
    toRadius: spot.radius,
    fromRing: ringAt(p),
    toRing: spot.ring,
    fromLift: liftAt(p),
    toLift: spot.lift,
    fromTagness: tagnessAt(p),
    toTagness: spot.tag == null ? 0 : 1,
    tag: spot.tag ?? tag,
  );
}
