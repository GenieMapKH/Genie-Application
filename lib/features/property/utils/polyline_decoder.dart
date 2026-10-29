import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The points of a Google encoded polyline (precision 5), in order.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  int nextDelta() {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += nextDelta();
    lng += nextDelta();
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
