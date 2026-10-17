import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/utils/map/layers/clustered_layer.dart';
import 'package:genie/features/home/utils/map/layers/layer_geometry.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('layer geometry', () {
    test('midpointOf is halfway between two points', () {
      final mid = midpointOf(const LatLng(10, 100), const LatLng(12, 104));

      expect(mid, const LatLng(11, 102));
    });

    test('centroidOf averages all points', () {
      final centroid = centroidOf(const [
        LatLng(0, 0),
        LatLng(0, 4),
        LatLng(4, 4),
        LatLng(4, 0),
      ]);

      expect(centroid, const LatLng(2, 2));
    });

    test('bigger plots show their details at a lower zoom', () {
      expect(shouldShowDetailedView(2000000, 12.5), isTrue);
      expect(shouldShowDetailedView(150, 12.5), isFalse);
      expect(shouldShowDetailedView(150, 19.0), isTrue);
      expect(shouldShowDetailedView(10, 20.5), isTrue);
      expect(shouldShowDetailedView(10, 19.0), isFalse);
    });

    test('label font size stays within readable bounds', () {
      for (final zoom in [10.0, 15.0, 18.5, 21.0]) {
        for (final area in [0.0, 500.0, 50000.0, 5000000.0]) {
          final size = labelFontSize(area, zoom, isArea: true);
          expect(size, inInclusiveRange(10.0, 20.0));
        }
      }
    });

    test('area labels are never smaller than edge labels', () {
      expect(
        labelFontSize(1000, 17, isArea: true),
        greaterThanOrEqualTo(labelFontSize(1000, 17, isArea: false)),
      );
    });
  });

  group('ClusteredLayer', () {
    test('places one marker per province that has listings', () {
      final markers = <Marker>{};
      const phnomPenh = LatLng(11.56, 104.92);

      ClusteredLayer.build(
        const [phnomPenh, LatLng(11.57, 104.93), LatLng(13.36, 103.86)],
        markers,
        null,
      );

      // Two listings in Phnom Penh collapse to one dot; Siem Reap adds one.
      expect(markers, hasLength(2));
    });

    test('adds nothing when there are no listings', () {
      final markers = <Marker>{};

      ClusteredLayer.build(const [], markers, null);

      expect(markers, isEmpty);
    });
  });
}
