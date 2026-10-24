import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Where a boundary's labels go at a zoom, so none covers another on any
/// plot: long and thin, many-cornered or small. Labels are placed in order
/// of importance (the area, then corner numbers, then side lengths, longest
/// first) and one that would overlap an earlier one is left out. Side
/// lengths sit just outside the plot, beside their side. Zooming in gives
/// everything room and brings the left-out labels back.
abstract final class BoundaryLabelLayout {
  /// A corner number's marker, in logical px.
  static const Size cornerSize = Size(26, 26);

  /// Space between a side and its length label.
  static const double _sideGap = 2;

  /// Where [point] sits on the world map at [zoom], in logical pixels (the
  /// Web Mercator projection Google Maps draws with, 256 px tiles).
  static Offset toScreen(LatLng point, double zoom) {
    final scale = _worldSize(zoom);
    final sinLat = math
        .sin(point.latitude * math.pi / 180)
        .clamp(-0.9999, 0.9999);
    final x = (point.longitude + 180) / 360 * scale;
    final y =
        (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return Offset(x, y);
  }

  /// The map position at [screen], the inverse of [toScreen].
  static LatLng fromScreen(Offset screen, double zoom) {
    final scale = _worldSize(zoom);
    final lng = screen.dx / scale * 360 - 180;
    final n = math.pi * (1 - 2 * screen.dy / scale);
    final lat = math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
    return LatLng(lat, lng);
  }

  /// The screen box of a marker of [size] at [position], hung from its
  /// [anchor] as the map does (fractions of the image, may be outside 0–1).
  static Rect markerRect(
    LatLng position,
    Size size,
    Offset anchor,
    double zoom,
  ) {
    final at = toScreen(position, zoom);
    return Rect.fromLTWH(
      at.dx - anchor.dx * size.width,
      at.dy - anchor.dy * size.height,
      size.width,
      size.height,
    );
  }

  /// The corners whose numbers are drawn, in order: each one that overlaps
  /// neither [taken] nor a number already kept. Adds the kept numbers' boxes
  /// to [taken].
  static List<int> placeCorners(
    List<LatLng> points,
    double zoom,
    List<Rect> taken,
  ) {
    final shown = <int>[];
    for (var i = 0; i < points.length; i++) {
      final box = markerRect(
        points[i],
        cornerSize,
        const Offset(0.5, 0.5),
        zoom,
      );
      if (_overlapsAny(box, taken)) continue;
      shown.add(i);
      taken.add(box);
    }
    return shown;
  }

  /// Where each side's length label goes, by side index (side `i` runs from
  /// `points[i]` to the next corner), for labels of [sizes]. Each label
  /// tries, in turn: just outside its side, further out past the corner
  /// numbers, then just inside; it takes the first spot clear of [taken]
  /// and of longer sides' labels. A side shorter on screen than its label,
  /// or with no clear spot, is left out. Adds the placed boxes to [taken].
  static Map<int, LatLng> placeSides(
    List<LatLng> points,
    double zoom,
    List<Size> sizes,
    List<Rect> taken,
  ) {
    final screen = [for (final point in points) toScreen(point, zoom)];
    final clockwise = _signedArea(screen) > 0;
    Offset side(int i) => screen[(i + 1) % screen.length] - screen[i];

    final longestFirst = List.generate(screen.length, (i) => i)
      ..sort((a, b) => side(b).distance.compareTo(side(a).distance));

    final placed = <int, LatLng>{};
    for (final i in longestFirst) {
      final vector = side(i);
      final length = vector.distance;
      if (length == 0) continue;
      final direction = vector / length;
      final size = sizes[i];
      // How far the label reaches along the side, and away from it.
      final along =
          direction.dx.abs() * size.width + direction.dy.abs() * size.height;
      if (length < along) continue;

      // Turned a quarter away from the inside; on screen y points down.
      final outward = clockwise
          ? Offset(direction.dy, -direction.dx)
          : Offset(-direction.dy, direction.dx);
      final reach =
          (outward.dx.abs() * size.width + outward.dy.abs() * size.height) / 2;
      final middle = screen[i] + vector / 2;
      final clearOfCorners = cornerSize.longestSide / 2 + _sideGap;
      for (final offset in [
        reach + _sideGap,
        reach + clearOfCorners,
        -(reach + _sideGap),
      ]) {
        final centre = middle + outward * offset;
        final box = Rect.fromCenter(
          center: centre,
          width: size.width,
          height: size.height,
        );
        if (_overlapsAny(box, taken)) continue;
        taken.add(box);
        placed[i] = fromScreen(centre, zoom);
        break;
      }
    }
    return placed;
  }

  static double _worldSize(double zoom) => 256 * math.pow(2, zoom).toDouble();

  /// Positive when [points] run clockwise on screen.
  static double _signedArea(List<Offset> points) {
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum / 2;
  }

  static bool _overlapsAny(Rect box, List<Rect> taken) =>
      taken.any((other) => other.overlaps(box));
}
