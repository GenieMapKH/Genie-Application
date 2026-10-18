import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/utils/map/cluster_layout.dart';

/// One listing gliding from the spot that showed it to the one that will.
/// Drops heading for the same spot meet and fuse; drops leaving one spot
/// pull apart.
class LiquidDrop {
  final LatLng from;
  final LatLng to;
  final double fromRadius;
  final double toRadius;
  final double fromRing;
  final double toRing;
  final double fromLift;
  final double toLift;

  const LiquidDrop({
    required this.from,
    required this.to,
    required this.fromRadius,
    required this.toRadius,
    required this.fromRing,
    required this.toRing,
    this.fromLift = 0,
    this.toLift = 0,
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
      );

  bool get moves => from != to || fromRadius != toRadius || fromRing != toRing;

  /// Where the drop is at eased progress [t] (0 = start, 1 = end).
  LatLng positionAt(double t) => LatLng(
    lerpDouble(from.latitude, to.latitude, t)!,
    lerpDouble(from.longitude, to.longitude, t)!,
  );

  double radiusAt(double t) => lerpDouble(fromRadius, toRadius, t)!;

  double ringAt(double t) => lerpDouble(fromRing, toRing, t)!;

  double liftAt(double t) => lerpDouble(fromLift, toLift, t)!;

  /// From where this drop is at [t] to [spot].
  LiquidDrop redirectedAt(double t, ClusterSpot spot) => LiquidDrop(
    from: positionAt(t),
    to: spot.position,
    fromRadius: radiusAt(t),
    toRadius: spot.radius,
    fromRing: ringAt(t),
    toRing: spot.ring,
    fromLift: liftAt(t),
    toLift: spot.lift,
  );
}

/// The zoomed-out dots merging or splitting after the zoom level changed.
///
/// While it runs, the map's own dot and bubble markers ([hiddenMarkerIds])
/// are hidden and the drops are painted in their place.
class ClusterTransition {
  static const duration = Duration(milliseconds: 450);

  /// How the drops speed up and settle.
  static const curve = Curves.easeInOutCubic;

  /// More drops than this are not animated: the map just switches.
  static const maxDrops = 600;

  /// By listing key.
  final Map<String, LiquidDrop> drops;

  /// Counts on the bubbles being left (fading out) and being formed (fading
  /// in).
  final List<ClusterSpot> outgoingLabels;
  final List<ClusterSpot> incomingLabels;

  /// The new layout's markers, shown again when the drops have arrived.
  final Set<String> hiddenMarkerIds;
  final DateTime startedAt;

  const ClusterTransition({
    required this.drops,
    required this.outgoingLabels,
    required this.incomingLabels,
    required this.hiddenMarkerIds,
    required this.startedAt,
  });

  /// Linear progress at [now], from 0 to 1.
  double progressAt(DateTime now) {
    final elapsed = now.difference(startedAt).inMicroseconds;
    return (elapsed / duration.inMicroseconds).clamp(0.0, 1.0);
  }

  /// The animation from [from] to [to], or null when nothing would move.
  ///
  /// When [running] has not finished at [now], its drops carry on from where
  /// they are instead of jumping back to [from].
  static ClusterTransition? between({
    required ClusterLayout from,
    required ClusterLayout to,
    required DateTime now,
    ClusterTransition? running,
  }) {
    final t = running == null ? 1.0 : curve.transform(running.progressAt(now));
    final interrupted = running != null && t < 1.0;

    final drops = <String, LiquidDrop>{};
    for (final MapEntry(key: key, value: target) in to.spotOf.entries) {
      final inFlight = interrupted ? running.drops[key] : null;
      final start = from.spotOf[key];
      if (inFlight != null) {
        drops[key] = inFlight.redirectedAt(t, target);
      } else if (start != null) {
        drops[key] = LiquidDrop.between(start, target);
      }
    }

    if (drops.isEmpty || drops.length > maxDrops) return null;
    if (!drops.values.any((drop) => drop.moves)) return null;

    return ClusterTransition(
      drops: drops,
      // An interrupted animation's labels are mid-fade; dropping them is
      // less jarring than restarting their fade.
      outgoingLabels: interrupted
          ? const []
          : [
              for (final spot in from.spots)
                if (spot.count > 1) spot,
            ],
      incomingLabels: [
        for (final spot in to.spots)
          if (spot.count > 1) spot,
      ],
      hiddenMarkerIds: {for (final spot in to.spots) spot.markerId},
      startedAt: now,
    );
  }
}
