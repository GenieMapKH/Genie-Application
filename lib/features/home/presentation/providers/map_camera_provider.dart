import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Where the main map's camera currently is.
class MapCamera {
  final LatLng center;
  final double zoom;

  /// Rotation and tilt, in degrees; both 0 for a flat, north-up map.
  final double bearing;
  final double tilt;

  const MapCamera({
    required this.center,
    required this.zoom,
    this.bearing = 0,
    this.tilt = 0,
  });

  bool get isFlatNorthUp => bearing == 0 && tilt == 0;
}

/// Live camera position of the main map.
///
/// Kept apart from `MapState` on purpose: it changes on every frame while the
/// user pans or zooms. Never `watch` it from a widget — read it on demand —
/// or the map would rebuild at the display's refresh rate and drop frames.
final mapCameraProvider = StateProvider<MapCamera>(
  (ref) => const MapCamera(center: LatLng(11.5564, 104.9282), zoom: 14.4746),
);
