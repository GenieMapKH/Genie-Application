import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Point halfway between [a] and [b].
LatLng midpointOf(LatLng a, LatLng b) {
  return LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);
}

/// Average position of [points] (must not be empty).
LatLng centroidOf(List<LatLng> points) {
  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final point in points) {
    sumLat += point.latitude;
    sumLng += point.longitude;
  }
  return LatLng(sumLat / points.length, sumLng / points.length);
}

/// Whether a polygon of [area] m² is zoomed in enough to show its vertex
/// numbers and edge lengths. Bigger plots need less zoom.
bool shouldShowDetailedView(double area, double currentZoom) {
  if (area > 1000000) return currentZoom > 12.0; // 100 ha
  if (area > 100000) return currentZoom > 13.0; // 10 ha
  if (area > 10000) return currentZoom > 14.5; // 1 ha
  if (area > 5000) return currentZoom > 15.5;
  if (area > 1000) return currentZoom > 16.5;
  if (area > 500) return currentZoom > 17.5;
  if (area > 100) return currentZoom > 18.5;
  if (area > 50) return currentZoom > 19.5;
  return currentZoom > 20.0;
}

/// Font size of the length/area labels for the current zoom. The same for
/// any plot size: a big plot is seen from further out, where its sides are
/// short on screen, so bigger labels only crowd it.
double labelFontSize(double area, double currentZoom, {required bool isArea}) {
  var size = isArea ? 13.5 : 11.0;

  if (currentZoom >= 19.0) {
    size *= 1.1;
  } else if (currentZoom >= 18.0) {
    size *= 1.05;
  }

  // The 13.0 branch is shadowed by the 15.0 one; kept as it always behaved.
  if (currentZoom <= 15.0) {
    size *= 0.8;
  } else if (currentZoom <= 13.0) {
    size *= 0.6;
  }

  return size.clamp(10.0, 20.0);
}
