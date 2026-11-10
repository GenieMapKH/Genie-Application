import 'package:tilomnov/features/home/utils/map/cluster_label.dart';
import 'package:tilomnov/features/home/utils/map/cluster_layout.dart';
import 'package:tilomnov/features/home/utils/map/liquid_drop.dart';

/// The listing markers merging or splitting after the zoom level changed:
/// dots into bubbles and back, and bubbles into price tags and back.
///
/// While it runs, the map's own markers of the new layout
/// ([hiddenMarkerIds]) are hidden and the drops are painted in their place.
class ClusterTransition {
  /// Among dots and bubbles.
  static const glideDuration = Duration(milliseconds: 450);

  /// To or from price tags, which also change shape.
  static const reshapeDuration = Duration(milliseconds: 600);

  /// More drops than this are not animated: the map just switches.
  static const maxDrops = 600;

  /// By listing key.
  final Map<String, LiquidDrop> drops;

  /// Counts and prices: on the markers being left (fading out), being
  /// formed (fading in), and on those there before and after (kept).
  final List<ClusterLabel> labels;

  /// The new layout's markers, shown again when the drops have arrived.
  final Set<String> hiddenMarkerIds;
  final DateTime startedAt;
  final Duration duration;

  const ClusterTransition({
    required this.drops,
    required this.labels,
    required this.hiddenMarkerIds,
    required this.startedAt,
    this.duration = glideDuration,
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
    final p = running == null ? 1.0 : running.progressAt(now);
    final interrupted = running != null && p < 1.0;

    final drops = <String, LiquidDrop>{};
    for (final MapEntry(key: key, value: target) in to.spotOf.entries) {
      final inFlight = interrupted ? running.drops[key] : null;
      final start = from.spotOf[key];
      if (inFlight != null) {
        drops[key] = inFlight.redirectedAt(p, target);
      } else if (start != null) {
        drops[key] = LiquidDrop.between(start, target);
      }
    }

    if (drops.isEmpty || drops.length > maxDrops) return null;
    if (!drops.values.any((drop) => drop.moves)) return null;

    // An interrupted animation's labels carry on from how they look now
    // rather than vanishing or restarting their fade.
    final showing = interrupted
        ? [
            for (final label in running.labels)
              label.heldAt(p, running.drops, drops),
          ]
        : ClusterLabel.showingIn(from, drops);
    return ClusterTransition(
      drops: drops,
      labels: ClusterLabel.fading(showing: showing, to: to, drops: drops),
      hiddenMarkerIds: {for (final spot in to.spots) spot.markerId},
      startedAt: now,
      duration: drops.values.any((d) => d.fromTagness != d.toTagness)
          ? reshapeDuration
          : glideDuration,
    );
  }
}
