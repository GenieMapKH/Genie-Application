import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tilomnov/features/home/utils/map/map_camera_focus.dart';

void main() {
  group('zoomToFit', () {
    test('falls back to the pin zoom for a single point', () {
      expect(
        MapCameraFocus.zoomToFit(const [LatLng(11.5, 104.9)], 400, 600),
        MapCameraFocus.pinZoom,
      );
    });

    test('zooms further out for a larger boundary', () {
      const small = [LatLng(11.5000, 104.9000), LatLng(11.5005, 104.9005)];
      const large = [LatLng(11.5000, 104.9000), LatLng(11.5100, 104.9100)];

      final smallZoom = MapCameraFocus.zoomToFit(small, 400, 600);
      final largeZoom = MapCameraFocus.zoomToFit(large, 400, 600);

      expect(largeZoom, lessThan(smallZoom));
    });

    test('zooms out when the viewport shrinks', () {
      const points = [LatLng(11.5000, 104.9000), LatLng(11.5040, 104.9040)];

      final tallZoom = MapCameraFocus.zoomToFit(points, 400, 700);
      final shortZoom = MapCameraFocus.zoomToFit(points, 400, 300);

      expect(shortZoom, lessThan(tallZoom));
    });

    test('stays within the supported zoom range', () {
      // A boundary spanning most of a country must not exceed the min zoom.
      const huge = [LatLng(10.0, 103.0), LatLng(14.0, 107.0)];
      final zoom = MapCameraFocus.zoomToFit(huge, 400, 600);

      expect(zoom, greaterThanOrEqualTo(11.0));
      expect(zoom, lessThanOrEqualTo(21.0));
    });
  });

  group('offsetForBottomInset', () {
    const center = LatLng(11.5, 104.9);

    test('returns the centre unchanged when nothing is obscured', () {
      expect(MapCameraFocus.offsetForBottomInset(center, 18, 0), center);
    });

    test('shifts the target south so the property clears the card', () {
      final shifted = MapCameraFocus.offsetForBottomInset(center, 18, 360);

      // Southward means a smaller latitude in the northern hemisphere.
      expect(shifted.latitude, lessThan(center.latitude));
      expect(shifted.longitude, closeTo(center.longitude, 1e-9));
    });

    test('shifts less at higher zoom, where a pixel spans less ground', () {
      final atLowZoom = MapCameraFocus.offsetForBottomInset(
        center,
        15,
        360,
      ).latitude;
      final atHighZoom = MapCameraFocus.offsetForBottomInset(
        center,
        19,
        360,
      ).latitude;

      final lowShift = center.latitude - atLowZoom;
      final highShift = center.latitude - atHighZoom;

      expect(highShift, lessThan(lowShift));
    });
  });

  group('frame', () {
    final road = LatLngBounds(
      southwest: const LatLng(11.50, 104.85),
      northeast: const LatLng(11.54, 104.89),
    );
    const screen = Size(400, 800);

    test('centres the area when nothing covers the map', () {
      final camera = MapCameraFocus.frame(road, screen, EdgeInsets.zero);

      expect(camera.target.latitude, closeTo(11.52, 1e-6));
      expect(camera.target.longitude, closeTo(104.87, 1e-6));
    });

    test('moves the area into the part a bottom sheet leaves visible', () {
      final camera = MapCameraFocus.frame(
        road,
        screen,
        const EdgeInsets.only(bottom: 400),
      );
      // The camera looks south of the area, so the area shows higher up.
      expect(camera.target.latitude, lessThan(11.52));
      expect(camera.target.longitude, closeTo(104.87, 1e-6));
    });

    test('moves the area beside a side panel', () {
      final camera = MapCameraFocus.frame(
        road,
        const Size(1024, 768),
        const EdgeInsets.only(left: 420),
      );
      // The camera looks west of the area, so the area shows to the right.
      expect(camera.target.longitude, lessThan(104.87));
    });

    test('zooms in less when more of the map is covered', () {
      final open = MapCameraFocus.frame(road, screen, EdgeInsets.zero);
      final covered = MapCameraFocus.frame(
        road,
        screen,
        const EdgeInsets.only(top: 180, bottom: 400),
      );
      expect(covered.zoom, lessThan(open.zoom));
    });

    test('stays zoomed in enough to show listings when the area is huge', () {
      final district = LatLngBounds(
        southwest: const LatLng(11.40, 104.70),
        northeast: const LatLng(11.65, 105.00),
      );
      expect(
        MapCameraFocus.frame(district, screen, EdgeInsets.zero).zoom,
        lessThan(13),
      );
      expect(
        MapCameraFocus.frame(
          district,
          screen,
          EdgeInsets.zero,
          minZoom: 14,
        ).zoom,
        14,
      );
    });

    test('never comes closer than the street level for a single spot', () {
      final spot = LatLngBounds(
        southwest: const LatLng(11.52, 104.87),
        northeast: const LatLng(11.52, 104.87),
      );
      expect(MapCameraFocus.frame(spot, screen, EdgeInsets.zero).zoom, 17);
    });
  });

  group('a scanned boundary', () {
    // About 40 m across, the size of a house plot.
    const corners = [
      LatLng(11.55000, 104.92000),
      LatLng(11.55030, 104.92035),
      LatLng(11.54990, 104.92060),
      LatLng(11.54960, 104.92020),
    ];
    const screen = Size(400, 840);
    const covered = EdgeInsets.only(top: 40, bottom: 272);

    test('its bounds hold every corner', () {
      final bounds = MapCameraFocus.boundsOf(corners);
      expect(bounds.southwest, const LatLng(11.54960, 104.92000));
      expect(bounds.northeast, const LatLng(11.55030, 104.92060));
    });

    test('shows every corner above the drawing buttons', () {
      final camera = MapCameraFocus.frame(
        MapCameraFocus.boundsOf(corners),
        screen,
        covered,
        maxZoom: 20,
      );
      final centre = MapCameraFocus.worldPixel(camera.target, camera.zoom);
      for (final corner in corners) {
        final pixel = MapCameraFocus.worldPixel(corner, camera.zoom);
        final x = pixel.x - centre.x + screen.width / 2;
        final y = pixel.y - centre.y + screen.height / 2;
        expect(x, inInclusiveRange(0, screen.width), reason: '$corner');
        expect(
          y,
          inInclusiveRange(covered.top, screen.height - covered.bottom),
          reason: '$corner',
        );
      }
      // Close enough to drag the corners apart.
      expect(camera.zoom, greaterThan(18));
    });
  });
}
