import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class LandMeasurements {
  final double area;
  final double perimeter;
  final double width;
  final double height;
  final List<double> sides;

  LandMeasurements({
    required this.area,
    required this.perimeter,
    required this.width,
    required this.height,
    required this.sides,
  });
}

LandMeasurements? calculateMeasurements(List<gmaps.LatLng> mapPoints) {
  if (mapPoints.length < 3) return null;

  // Convert your map points to maps_toolkit LatLng objects
  List<LatLng> toolkitPoints = mapPoints
      .map((p) => LatLng(p.latitude, p.longitude))
      .toList();

  // 1. AREA
  // computeArea returns square meters on the surface of the Earth
  double area = SphericalUtil.computeArea(toolkitPoints).toDouble();

  // 2. PERIMETER & SIDE LENGTHS
  double perimeter = 0.0;
  List<double> sides = [];

  for (int i = 0; i < toolkitPoints.length; i++) {
    // Get current point and next point (wrap around to the first point at the end)
    LatLng p1 = toolkitPoints[i];
    LatLng p2 = toolkitPoints[(i + 1) % toolkitPoints.length];

    // Compute distance between the two points
    double dist = SphericalUtil.computeDistanceBetween(p1, p2).toDouble();
    sides.add(dist);
    perimeter += dist;
  }

  // 3. BOUNDING BOX (WIDTH & HEIGHT)
  double minLat = toolkitPoints.first.latitude;
  double maxLat = toolkitPoints.first.latitude;
  double minLng = toolkitPoints.first.longitude;
  double maxLng = toolkitPoints.first.longitude;

  for (var point in toolkitPoints) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }

  // Width = Distance from West to East (minLng to maxLng at minLat)
  double width = SphericalUtil.computeDistanceBetween(
    LatLng(minLat, minLng),
    LatLng(minLat, maxLng),
  ).toDouble();

  // Height = Distance from South to North (minLat to maxLat at minLng)
  double height = SphericalUtil.computeDistanceBetween(
    LatLng(minLat, minLng),
    LatLng(maxLat, minLng),
  ).toDouble();

  return LandMeasurements(
    area: area,
    perimeter: perimeter,
    width: width,
    height: height,
    sides: sides,
  );
}
