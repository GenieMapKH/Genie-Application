import 'dart:math' as math;

import 'package:flutter/widgets.dart' show EdgeInsets, Size;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapCameraFocus {
  static const double _tileSize = 256.0;
  static const double _minZoom = 11.0;
  static const double _maxZoom = 21.0;

  /// Zoom used for properties that only have a pin, with no drawn boundary.
  static const double pinZoom = 18.0;

  static double _mercatorX(double lng) => lng / 360.0 + 0.5;

  static double _mercatorY(double lat) {
    final sin = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
    return 0.5 - math.log((1 + sin) / (1 - sin)) / (4 * math.pi);
  }

  static double _latFromMercatorY(double y) {
    final n = math.pi * (1 - 2 * y);
    return 180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  /// Where [point] sits on the whole-world map at [zoom], in logical pixels.
  static math.Point<double> worldPixel(LatLng point, double zoom) {
    final worldPixels = _tileSize * math.pow(2, zoom);
    return math.Point(
      _mercatorX(point.longitude) * worldPixels,
      _mercatorY(point.latitude) * worldPixels,
    );
  }

  /// The zoom at which [points] fit inside a [width] x [height] viewport
  /// (logical pixels), leaving [padding] of breathing room on each side.
  static double zoomToFit(
    List<LatLng> points,
    double width,
    double height, {
    double padding = 56,
  }) {
    if (points.length < 2) return pinZoom;

    double minX = 1, maxX = 0, minY = 1, maxY = 0;
    for (final point in points) {
      final x = _mercatorX(point.longitude);
      final y = _mercatorY(point.latitude);
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }

    final spanX = math.max(maxX - minX, 1e-9);
    final spanY = math.max(maxY - minY, 1e-9);
    final usableWidth = math.max(width - padding * 2, 1.0);
    final usableHeight = math.max(height - padding * 2, 1.0);

    final zoomX = math.log(usableWidth / (_tileSize * spanX)) / math.ln2;
    final zoomY = math.log(usableHeight / (_tileSize * spanY)) / math.ln2;

    return math.min(zoomX, zoomY).clamp(_minZoom, _maxZoom);
  }

  /// The camera that shows all of [bounds] inside the part of a [mapSize] map
  /// not covered by [covered] (panels, bars). Never closer than [maxZoom], so
  /// a single listing still shows its surroundings, and never further than
  /// [minZoom] when the area is too big to fit at that zoom.
  static CameraPosition frame(
    LatLngBounds bounds,
    Size mapSize,
    EdgeInsets covered, {
    double maxZoom = 17,
    double minZoom = 0,
  }) {
    // [minZoom] wins over fitting everything: a big area is better shown
    // close enough to read than as a view too far out to show anything.
    final zoom = math
        .min(
          zoomToFit(
            [bounds.southwest, bounds.northeast],
            mapSize.width - covered.horizontal,
            mapSize.height - covered.vertical,
            padding: 32,
          ),
          maxZoom,
        )
        .clamp(minZoom, maxZoom);
    final center = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );

    // Move the camera so [center] lands in the middle of the visible part.
    final worldPixels = _tileSize * math.pow(2, zoom);
    final x =
        _mercatorX(center.longitude) +
        ((covered.right - covered.left) / 2) / worldPixels;
    final y =
        (_mercatorY(center.latitude) +
                ((covered.bottom - covered.top) / 2) / worldPixels)
            .clamp(0.0, 1.0);

    return CameraPosition(
      target: LatLng(_latFromMercatorY(y), (x - 0.5) * 360.0),
      zoom: zoom,
    );
  }

  /// Shifts [center] south by half of [bottomInset] pixels so the property sits
  /// in the middle of the visible area rather than behind the card.
  static LatLng offsetForBottomInset(
    LatLng center,
    double zoom,
    double bottomInset, {
    double topInset = 0.0,
  }) {
    if (bottomInset <= 0 && topInset <= 0) return center;

    final worldPixels = _tileSize * math.pow(2, zoom);
    final targetY =
        (_mercatorY(center.latitude) +
                ((bottomInset - topInset) / 2) / worldPixels)
            .clamp(0.0, 1.0);

    return LatLng(_latFromMercatorY(targetY), center.longitude);
  }
}
