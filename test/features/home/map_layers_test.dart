import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/utils/map/layers/layer_geometry.dart';
import 'package:tilomnov/features/home/utils/map/screen_clustering.dart';
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

  group('clusterByScreenDistance', () {
    const phnomPenh = LatLng(11.5564, 104.9282);
    const nearPhnomPenh = LatLng(11.5570, 104.9290); // ~100 m away
    const siemReap = LatLng(13.3611, 103.8606);
    // Far corner of Siem Reap province, ~60 km from its centre.
    const siemReapEdge = LatLng(13.9, 104.2);

    test('merges listings whose dots would overlap', () {
      final clusters = clusterByScreenDistance(const [
        phnomPenh,
        nearPhnomPenh,
        siemReap,
      ], 8);

      expect(clusters, hasLength(2));
      expect(clusters.first.indices, [0, 1]);
      expect(clusters.last.indices, [2]);
    });

    test('keeps an outlying listing at its real position', () {
      final clusters = clusterByScreenDistance(const [
        siemReap,
        siemReapEdge,
      ], 9);

      expect(clusters, hasLength(2));
      expect(clusters.last.position, siemReapEdge);
    });

    test('a cluster sits at the average of its members', () {
      final clusters = clusterByScreenDistance(const [
        LatLng(11.0, 104.0),
        LatLng(11.002, 104.002),
      ], 8);

      expect(clusters.single.position.latitude, closeTo(11.001, 1e-9));
      expect(clusters.single.position.longitude, closeTo(104.001, 1e-9));
    });

    test('zooming in splits a cluster apart', () {
      const points = [phnomPenh, nearPhnomPenh];

      expect(clusterByScreenDistance(points, 10), hasLength(1));
      expect(clusterByScreenDistance(points, 18), hasLength(2));
    });

    test('returns nothing when there are no listings', () {
      expect(clusterByScreenDistance(const [], 8), isEmpty);
    });
  });
}
