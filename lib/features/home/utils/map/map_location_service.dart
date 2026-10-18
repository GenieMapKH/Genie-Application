import 'dart:async';

import 'package:genie/core/logging/app_logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Why the device's position could not be had. The map says it in the
/// user's language.
enum LocationProblem { servicesOff, denied, deniedForever, failed }

/// Result of a location request: either a position, or the reason it failed so
/// the caller can surface a message.
class LocationResult {
  final Position? position;
  final LocationProblem? error;

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
      return const LocationResult.failure(LocationProblem.servicesOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationProblem.denied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure(LocationProblem.deniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult.success(position);
    } catch (e) {
      AppLogger.error('Could not get the location', e);
      return const LocationResult.failure(LocationProblem.failed);
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
