import 'package:google_maps_flutter/google_maps_flutter.dart';

/// One marker of the zoomed-out map: a lone listing's dot, or a bubble
/// standing for [count] listings.
class ClusterSpot {
  /// The Google Maps marker drawn for it.
  final String markerId;
  final LatLng position;
  final int count;

  /// Outer radius, and the width of the light ring inside it, in logical
  /// pixels.
  final double radius;
  final double ring;

  /// How many logical pixels above [position] the marker's circle is drawn.
  final double lift;

  const ClusterSpot({
    required this.markerId,
    required this.position,
    required this.count,
    required this.radius,
    required this.ring,
    this.lift = 0,
  });
}

/// Where every listing is drawn on the zoomed-out map at one zoom level, so
/// a change of level can be animated from one layout to the next.
class ClusterLayout {
  /// The whole zoom level the clusters were made for.
  final int zoomLevel;

  /// The spot showing each listing, by listing key.
  final Map<String, ClusterSpot> spotOf;

  const ClusterLayout({required this.zoomLevel, required this.spotOf});

  /// Each spot once, however many listings it holds.
  Iterable<ClusterSpot> get spots => spotOf.values.toSet();
}
