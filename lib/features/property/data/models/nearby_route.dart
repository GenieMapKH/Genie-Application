import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The road from a listing to one of its nearby places, as the server drew it.
class NearbyRoute {
  final int meters;

  /// From the listing to the place.
  final List<LatLng> points;

  const NearbyRoute({required this.meters, required this.points});
}
