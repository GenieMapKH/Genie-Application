import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/utils/map/layers/boundary_label_layout.dart';
import 'package:tilomnov/features/home/utils/map/layers/layer_geometry.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// About 1 m of latitude in degrees; longitude near 11.5° N is close enough.
const _metre = 1 / 111000;

LatLng _at(double north, double east) =>
    LatLng(11.5 + north * _metre, 104.9 + east * _metre);

/// A 500 m tall plot whose west side has a corner every 20 m, like a large
/// surveyed parcel: corners 1–26 up the west, then 27 and 28 on the east.
final _manyCorners = [
  for (var i = 0; i <= 25; i++) _at(i * 20, 0),
  _at(500, 400),
  _at(0, 400),
];

/// A 70 m by 16 m strip on a diagonal, as in a narrow roadside plot.
final _thinStrip = [_at(0, 0), _at(50, 50), _at(39, 61), _at(-11, 11)];

const _sideLabel = Size(44, 24);
const _areaLabel = Size(80, 30);

/// A 60 m square with its north-east quarter cut out.
final _lShape = [
  _at(0, 0),
  _at(60, 0),
  _at(60, 30),
  _at(30, 30),
  _at(30, 60),
  _at(0, 60),
];

/// Lays a plot out the way the map does and returns every box it used.
List<Rect> _layOut(List<LatLng> points, double zoom) {
  final taken = [
    BoundaryLabelLayout.markerRect(
      centroidOf(points),
      _areaLabel,
      const Offset(0.5, 0.5),
      zoom,
    ),
  ];
  BoundaryLabelLayout.placeCorners(points, zoom, taken);
  BoundaryLabelLayout.placeSides(
    points,
    zoom,
    List.filled(points.length, _sideLabel),
    taken,
  );
  return taken;
}

/// Ray casting on the screen outline.
bool _inside(Offset point, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    if ((a.dy > point.dy) != (b.dy > point.dy) &&
        point.dx < (b.dx - a.dx) * (point.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}

void main() {
  group('projection', () {
    test('puts the equator and prime meridian in the middle of the world', () {
      final point = BoundaryLabelLayout.toScreen(const LatLng(0, 0), 0);
      expect(point.dx, closeTo(128, 0.001));
      expect(point.dy, closeTo(128, 0.001));
    });

    test('doubles distances with every zoom level', () {
      double length(double zoom) =>
          (BoundaryLabelLayout.toScreen(_manyCorners[0], zoom) -
                  BoundaryLabelLayout.toScreen(_manyCorners[1], zoom))
              .distance;
      expect(length(16), closeTo(length(15) * 2, 0.001));
    });

    test('fromScreen undoes toScreen', () {
      final point = _thinStrip[2];
      final back = BoundaryLabelLayout.fromScreen(
        BoundaryLabelLayout.toScreen(point, 17),
        17,
      );
      expect(back.latitude, closeTo(point.latitude, 1e-9));
      expect(back.longitude, closeTo(point.longitude, 1e-9));
    });
  });

  test('no two labels ever overlap, on any plot at any zoom', () {
    for (final plot in [_manyCorners, _thinStrip]) {
      for (final zoom in [13.0, 15.0, 17.0, 19.0, 21.0]) {
        final boxes = _layOut(plot, zoom);
        for (var i = 0; i < boxes.length; i++) {
          for (var j = i + 1; j < boxes.length; j++) {
            expect(
              boxes[i].overlaps(boxes[j]),
              isFalse,
              reason: 'zoom $zoom, boxes $i and $j',
            );
          }
        }
      }
    }
  });

  group('placeCorners', () {
    test('zoomed out, keeps the first corner and drops the crowded ones', () {
      final shown = BoundaryLabelLayout.placeCorners(_manyCorners, 14, []);
      expect(shown.first, 0);
      expect(shown.length, lessThan(_manyCorners.length ~/ 2));
    });

    test('zoomed in far enough, shows every corner', () {
      expect(
        BoundaryLabelLayout.placeCorners(_manyCorners, 20, []),
        List.generate(_manyCorners.length, (i) => i),
      );
    });

    test('gives way to the area label', () {
      final everywhere = [const Rect.fromLTWH(-1e12, -1e12, 2e12, 2e12)];
      expect(
        BoundaryLabelLayout.placeCorners(_thinStrip, 18, everywhere),
        isEmpty,
      );
    });
  });

  group('placeSides', () {
    test('puts a thin plot\'s long sides outside it, clear of the area', () {
      const zoom = 18.0;
      final taken = [
        BoundaryLabelLayout.markerRect(
          centroidOf(_thinStrip),
          _areaLabel,
          const Offset(0.5, 0.5),
          zoom,
        ),
      ];
      final placed = BoundaryLabelLayout.placeSides(
        _thinStrip,
        zoom,
        List.filled(4, _sideLabel),
        taken,
      );

      // Sides 0 and 2 are the 70 m ones.
      expect(placed.keys, containsAll([0, 2]));
      final outline = [
        for (final point in _thinStrip)
          BoundaryLabelLayout.toScreen(point, zoom),
      ];
      for (final side in [0, 2]) {
        final centre = BoundaryLabelLayout.toScreen(placed[side]!, zoom);
        expect(_inside(centre, outline), isFalse);
      }
    });

    test('leaves out a side shorter on screen than its label', () {
      final placed = BoundaryLabelLayout.placeSides(
        _manyCorners,
        15,
        List.filled(_manyCorners.length, _sideLabel),
        [],
      );
      // The 20 m west sides are ~4 px at zoom 15; the long ones fit.
      expect(placed.keys.where((i) => i < 25), isEmpty);
      expect(placed.keys, containsAll([25, 26, 27]));
    });
  });

  group('fitsInside', () {
    Rect areaBoxAt(LatLng position, double zoom) =>
        BoundaryLabelLayout.markerRect(
          position,
          _areaLabel,
          const Offset(0.5, 0.5),
          zoom,
        );

    test('the area fits on a plot big enough on screen', () {
      final square = [_at(0, 0), _at(60, 0), _at(60, 60), _at(0, 60)];
      final box = areaBoxAt(centroidOf(square), 19);
      expect(BoundaryLabelLayout.fitsInside(box, square, 19), isTrue);
    });

    test('the area does not fit on a plot too small on screen', () {
      final square = [_at(0, 0), _at(60, 0), _at(60, 60), _at(0, 60)];
      final box = areaBoxAt(centroidOf(square), 16);
      expect(BoundaryLabelLayout.fitsInside(box, square, 16), isFalse);
    });

    test('the area does not fit across a thin strip', () {
      final box = areaBoxAt(centroidOf(_thinStrip), 19);
      expect(BoundaryLabelLayout.fitsInside(box, _thinStrip, 19), isFalse);
    });

    test('a box over the cut-out corner of an L-shape does not fit', () {
      // Centred on the inner corner: three of its corners are on the plot,
      // the fourth in the cut-out.
      final box = areaBoxAt(_at(30, 30), 19);
      expect(BoundaryLabelLayout.fitsInside(box, _lShape, 19), isFalse);
      final inArm = areaBoxAt(_at(15, 15), 19);
      expect(BoundaryLabelLayout.fitsInside(inArm, _lShape, 19), isTrue);
    });
  });

  test('labels on a big plot are no bigger than on a small one', () {
    for (final zoom in [13.0, 15.0, 17.0, 19.0]) {
      for (final isArea in [true, false]) {
        expect(
          labelFontSize(5000000, zoom, isArea: isArea),
          labelFontSize(500, zoom, isArea: isArea),
        );
      }
    }
  });
}
