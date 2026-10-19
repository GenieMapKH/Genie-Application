import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/utils/map/markers/price_tag_layout.dart';

/// One listing marker: a lone listing's dot, a bubble standing for [count]
/// listings, or, zoomed in, a listing's price [tag].
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

  /// The price tag drawn in its place zoomed in. [radius] and [ring] are
  /// then the dot it shrinks into on the way to a bubble.
  final PriceTagLayout? tag;

  const ClusterSpot({
    required this.markerId,
    required this.position,
    required this.count,
    required this.radius,
    required this.ring,
    this.lift = 0,
    this.tag,
  });
}

/// Where every listing is drawn on the map at one zoom level, as a dot,
/// bubble or price tag, so a change of level can be animated from one layout
/// to the next.
class ClusterLayout {
  /// The whole zoom level the clusters were made for.
  final int zoomLevel;

  /// The spot showing each listing, by listing key.
  final Map<String, ClusterSpot> spotOf;

  const ClusterLayout({required this.zoomLevel, required this.spotOf});

  /// Each spot once, however many listings it holds.
  Iterable<ClusterSpot> get spots => spotOf.values.toSet();
}
