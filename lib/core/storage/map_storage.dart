import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapStorage {
  static const _storage = FlutterSecureStorage();
  static const _latKey = 'last_map_lat';
  static const _lngKey = 'last_map_lng';
  static const _zoomKey = 'last_map_zoom';

  static Future<void> saveLastPosition(CameraPosition position) async {
    await _storage.write(
      key: _latKey,
      value: position.target.latitude.toString(),
    );
    await _storage.write(
      key: _lngKey,
      value: position.target.longitude.toString(),
    );
    await _storage.write(key: _zoomKey, value: position.zoom.toString());
  }

  static Future<CameraPosition?> getLastPosition() async {
    final latStr = await _storage.read(key: _latKey);
    final lngStr = await _storage.read(key: _lngKey);
    final zoomStr = await _storage.read(key: _zoomKey);

    if (latStr != null && lngStr != null && zoomStr != null) {
      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);
      final zoom = double.tryParse(zoomStr);

      if (lat != null && lng != null && zoom != null) {
        return CameraPosition(target: LatLng(lat, lng), zoom: zoom);
      }
    }
    return null;
  }
}
