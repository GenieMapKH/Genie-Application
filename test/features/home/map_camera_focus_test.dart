import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:genie/features/home/utils/map/map_camera_focus.dart';

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
}
