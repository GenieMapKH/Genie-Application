import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/utils/map/cluster_layout.dart';
import 'package:tilomnov/features/home/utils/map/cluster_transition.dart';
import 'package:tilomnov/features/home/utils/map/markers/property_markers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _a = LatLng(11.55, 104.91);
const _b = LatLng(11.55, 104.93);
const _middle = LatLng(11.55, 104.92);

ClusterSpot _dot(String id, LatLng position) => ClusterSpot(
  markerId: id,
  position: position,
  count: 1,
  radius: 12.5,
  ring: 1,
);

const _bubble = ClusterSpot(
  markerId: 'cluster_0',
  position: _middle,
  count: 2,
  radius: 17,
  ring: 2.5,
  lift: 2,
);

final _apart = ClusterLayout(
  zoomLevel: 13,
  spotOf: {'a': _dot('dot_0', _a), 'b': _dot('dot_1', _b)},
);
const _merged = ClusterLayout(
  zoomLevel: 12,
  spotOf: {'a': _bubble, 'b': _bubble},
);

final _start = DateTime(2026, 10, 18, 12);

void main() {
  test('merging: each dot flows into the bubble', () {
    final merge = ClusterTransition.between(
      from: _apart,
      to: _merged,
      now: _start,
    )!;

    expect(merge.drops['a']!.from, _a);
    expect(merge.drops['a']!.to, _middle);
    expect(merge.drops['b']!.to, _middle);
    expect(merge.drops['a']!.radiusAt(1), 17);
    expect(merge.drops['a']!.liftAt(1), 2);
    // The bubble's own marker waits until the drops have arrived.
    expect(merge.hiddenMarkerIds, {'cluster_0'});
    expect(merge.outgoingLabels, isEmpty);
    expect(merge.incomingLabels.single.count, 2);
  });

  test('splitting: the bubble pulls apart into dots', () {
    final split = ClusterTransition.between(
      from: _merged,
      to: _apart,
      now: _start,
    )!;

    expect(split.drops['a']!.from, _middle);
    expect(split.drops['a']!.to, _a);
    expect(split.drops['b']!.to, _b);
    expect(split.hiddenMarkerIds, {'dot_0', 'dot_1'});
    expect(split.outgoingLabels.single.count, 2);
    expect(split.incomingLabels, isEmpty);
  });

  test('nothing to animate when no dot moves', () {
    final sameSpots = ClusterLayout(zoomLevel: 12, spotOf: _apart.spotOf);
    expect(
      ClusterTransition.between(from: _apart, to: sameSpots, now: _start),
      isNull,
    );
  });

  test('a new zoom level mid-way carries the drops on from where they are', () {
    final merge = ClusterTransition.between(
      from: _apart,
      to: _merged,
      now: _start,
    )!;
    final halfway = _start.add(ClusterTransition.glideDuration ~/ 2);

    final split = ClusterTransition.between(
      from: _merged,
      to: _apart,
      now: halfway,
      running: merge,
    )!;

    expect(split.drops['a']!.from, merge.drops['a']!.positionAt(0.5));
    expect(split.drops['a']!.to, _a);
    // Its labels were mid-fade; they are not restarted.
    expect(split.outgoingLabels, isEmpty);
  });

  test('a finished animation is not continued', () {
    final merge = ClusterTransition.between(
      from: _apart,
      to: _merged,
      now: _start,
    )!;
    final later = _start.add(const Duration(seconds: 5));

    final split = ClusterTransition.between(
      from: _merged,
      to: _apart,
      now: later,
      running: merge,
    )!;

    expect(split.drops['a']!.from, _middle);
    expect(split.outgoingLabels, hasLength(1));
  });

  test('too many dots switch without animating', () {
    final many = ClusterLayout(
      zoomLevel: 13,
      spotOf: {
        for (var i = 0; i <= ClusterTransition.maxDrops; i++)
          'p$i': _dot('dot_$i', _a),
      },
    );
    final together = ClusterLayout(
      zoomLevel: 12,
      spotOf: {for (final key in many.spotOf.keys) key: _bubble},
    );

    expect(
      ClusterTransition.between(from: many, to: together, now: _start),
      isNull,
    );
  });

  group('price tags', () {
    ClusterSpot tagged(String id, LatLng position) => ClusterSpot(
      markerId: id,
      position: position,
      count: 1,
      radius: 12.5,
      ring: 1,
      tag: PropertyMarkers.priceTagLayout(price: r'$1,000'),
    );
    final tags = ClusterLayout(
      zoomLevel: 14,
      spotOf: {'a': tagged('city_dot_0', _a), 'b': tagged('city_dot_1', _b)},
    );

    test('a bubble splits, then each drop stretches into its tag', () {
      final split = ClusterTransition.between(
        from: _merged,
        to: tags,
        now: _start,
      )!;
      final a = split.drops['a']!;

      expect(split.duration, ClusterTransition.reshapeDuration);
      expect(split.hiddenMarkerIds, {'city_dot_0', 'city_dot_1'});
      // The prices fade in where the tags form.
      expect(split.incomingLabels.map((s) => s.markerId), hasLength(2));
      // Round while it travels, a tag once it has arrived.
      expect(a.tagnessAt(0.5), 0);
      expect(a.positionAt(0.7), _a);
      expect(a.tagnessAt(1), 1);
    });

    test('zooming out, each tag rounds into a drop before it flows', () {
      final merge = ClusterTransition.between(
        from: tags,
        to: _merged,
        now: _start,
      )!;
      final a = merge.drops['a']!;

      expect(merge.outgoingLabels, hasLength(2));
      expect(a.tagnessAt(0), 1);
      expect(a.positionAt(0.3), _a);
      expect(a.tagnessAt(0.45), 0);
      expect(a.positionAt(1), _middle);
    });

    test('tags that only change zoom level are not animated', () {
      final closer = ClusterLayout(zoomLevel: 15, spotOf: tags.spotOf);
      expect(
        ClusterTransition.between(from: tags, to: closer, now: _start),
        isNull,
      );
    });
  });
}
