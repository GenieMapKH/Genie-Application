import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result of a location request: either a position, or the reason it failed so
/// the caller can surface a message.
class LocationResult {
  final Position? position;
  final String? error;

  const LocationResult.success(this.position) : error = null;
  const LocationResult.failure(this.error) : position = null;

  bool get isSuccess => position != null;
}

/// Wraps Geolocator permission handling so the map layout doesn't have to.
class MapLocationService {
  /// Requests permission without prompting the user about failures — used on
  /// startup to warm up the location layer.
  static Future<void> warmUp() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  /// Resolves the device's current position, requesting permission if needed.
  static Future<LocationResult> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failure(
        'Location services are disabled. Please enable them.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(
        'Location permissions are permanently denied.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult.success(position);
    } catch (e) {
      return LocationResult.failure('Could not get location: $e');
    }
  }

  /// Moves [completer]'s map to [target].
  static Future<void> animateTo(
    Completer<GoogleMapController> completer,
    LatLng target, {
    double zoom = 22,
  }) async {
    final controller = await completer.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }
}
