import 'package:google_maps_flutter/google_maps_flutter.dart';

/// One mapped part of a place, including any excluded interior rings.
class SearchBoundary {
  final List<LatLng> points;
  final List<List<LatLng>> holes;

  const SearchBoundary({required this.points, this.holes = const []});

  /// Reads GeoJSON MultiPolygon coordinates; older servers supply no boundary.
  static List<SearchBoundary> fromJson(Object? raw) {
    if (raw is! Map<String, dynamic> || raw['type'] != 'MultiPolygon') {
      return const [];
    }
    final coordinates = raw['coordinates'];
    if (coordinates is! List) return const [];
    final boundaries = <SearchBoundary>[];
    for (final polygon in coordinates) {
      if (polygon is! List || polygon.isEmpty) return const [];
      final rings = <List<LatLng>>[];
      for (final ring in polygon) {
        if (ring is! List || ring.length < 4) return const [];
        final points = <LatLng>[];
        for (final point in ring) {
          if (point is! List || point.length != 2) return const [];
          final lng = point[0], lat = point[1];
          if (lng is! num ||
              lat is! num ||
              !lng.isFinite ||
              !lat.isFinite ||
              lng < -180 ||
              lng > 180 ||
              lat < -90 ||
              lat > 90) {
            return const [];
          }
          points.add(LatLng(lat.toDouble(), lng.toDouble()));
        }
        if (points.first != points.last) return const [];
        rings.add(List.unmodifiable(points));
      }
      boundaries.add(
        SearchBoundary(
          points: rings.first,
          holes: List.unmodifiable(rings.skip(1)),
        ),
      );
    }
    return List.unmodifiable(boundaries);
  }
}
