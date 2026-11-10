import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/utils/map/cluster_layout.dart';
import 'package:tilomnov/features/home/utils/map/liquid_drop.dart';

/// The count on a bubble or the price on a tag during a cluster transition.
///
/// A label rides along with the drop of [riderKey] when every listing it
/// stands for travels together, so a bubble's count goes where the bubble
/// goes; otherwise it stays at [position]. It fades from [fromOpacity] to
/// [toOpacity]: a label on a marker that is there before and after keeps
/// showing, one being left fades out, one being formed fades in.
class ClusterLabel {
  /// The marker whose count or price this is.
  final ClusterSpot spot;
  final LatLng position;
  final double lift;
  final String? riderKey;
  final double fromOpacity;
  final double toOpacity;

  const ClusterLabel({
    required this.spot,
    required this.position,
    required this.lift,
    required this.fromOpacity,
    required this.toOpacity,
    this.riderKey,
  });

  bool get isPrice => spot.tag != null;

  /// Prices go first, before their tag rounds into a drop, and come last,
  /// once it has taken shape; counts fade over longer.
  Interval get _fade => toOpacity >= fromOpacity
      ? (isPrice ? const Interval(0.8, 1) : const Interval(0.6, 1))
      : (isPrice ? const Interval(0, 0.15) : const Interval(0, 0.35));

  double opacityAt(double p) =>
      lerpDouble(fromOpacity, toOpacity, _fade.transform(p))!;

  /// Where the label is drawn at [p]: on its drop, or at its place.
  ({LatLng position, double lift}) placeAt(
    double p,
    Map<String, LiquidDrop> drops,
  ) {
    final drop = drops[riderKey];
    if (drop == null) return (position: position, lift: lift);
    return (position: drop.positionAt(p), lift: drop.liftAt(p));
  }

  /// This label as it stands at [p], about to be handed to a transition
  /// whose drops are [next]: still, at its current place and opacity.
  ClusterLabel heldAt(
    double p,
    Map<String, LiquidDrop> drops,
    Map<String, LiquidDrop> next,
  ) {
    final place = placeAt(p, drops);
    final opacity = opacityAt(p);
    return ClusterLabel(
      spot: spot,
      position: place.position,
      lift: place.lift,
      fromOpacity: opacity,
      toOpacity: opacity,
      // The rider's new drop starts from where the label is now.
      riderKey: next.containsKey(riderKey) ? riderKey : null,
    );
  }

  /// The labels of a transition into [to] whose drops are [drops], given
  /// those [showing] when it starts (each still, at its opacity then).
  ///
  /// A marker of [to] showing the same count or price at the same place as
  /// a label already there keeps that label, so it does not blink; the
  /// others fade in, and the labels left over fade out.
  static List<ClusterLabel> fading({
    required List<ClusterLabel> showing,
    required ClusterLayout to,
    required Map<String, LiquidDrop> drops,
  }) {
    final leftOver = [...showing];
    final labels = <ClusterLabel>[];
    for (final spot in labelledSpotsOf(to)) {
      final i = leftOver.indexWhere((label) => _sameLabel(label, spot, drops));
      final kept = i < 0 ? null : leftOver.removeAt(i);
      labels.add(
        ClusterLabel(
          spot: spot,
          position: spot.position,
          lift: spot.lift,
          fromOpacity: kept?.fromOpacity ?? 0,
          toOpacity: 1,
          riderKey: kept == null ? riderOf(to, spot, drops) : null,
        ),
      );
    }
    for (final label in leftOver) {
      if (label.fromOpacity <= 0) continue;
      labels.add(
        ClusterLabel(
          spot: label.spot,
          position: label.position,
          lift: label.lift,
          fromOpacity: label.fromOpacity,
          toOpacity: 0,
          riderKey: label.riderKey,
        ),
      );
    }
    return labels;
  }

  /// The labels of [layout]'s markers, fully shown and still.
  static List<ClusterLabel> showingIn(
    ClusterLayout layout,
    Map<String, LiquidDrop> drops,
  ) => [
    for (final spot in labelledSpotsOf(layout))
      ClusterLabel(
        spot: spot,
        position: spot.position,
        lift: spot.lift,
        fromOpacity: 1,
        toOpacity: 1,
        riderKey: riderOf(layout, spot, drops),
      ),
  ];

  /// The markers of [layout] that carry a count or a price.
  static Iterable<ClusterSpot> labelledSpotsOf(ClusterLayout layout) =>
      layout.spots.where((spot) => spot.count > 1 || spot.tag != null);

  /// A listing of [spot] in [layout] whose drop all its listings travel
  /// with, or null when they part ways or stay where they are.
  static String? riderOf(
    ClusterLayout layout,
    ClusterSpot spot,
    Map<String, LiquidDrop> drops,
  ) {
    String? rider;
    LiquidDrop? first;
    for (final MapEntry(:key, :value) in layout.spotOf.entries) {
      if (!identical(value, spot)) continue;
      final drop = drops[key];
      if (drop == null) continue;
      if (first == null) {
        first = drop;
        rider = key;
      } else if (drop.from != first.from || drop.to != first.to) {
        return null;
      }
    }
    if (first == null || first.from == first.to) return null;
    return rider;
  }

  /// Whether [label] already shows what [spot] will, where it will.
  static bool _sameLabel(
    ClusterLabel label,
    ClusterSpot spot,
    Map<String, LiquidDrop> drops,
  ) {
    final rider = drops[label.riderKey];
    final at = rider?.from ?? label.position;
    return at == spot.position &&
        label.spot.count == spot.count &&
        label.isPrice == (spot.tag != null);
  }
}
