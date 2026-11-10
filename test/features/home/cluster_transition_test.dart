import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/utils/map/cluster_label.dart';
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

/// The labels of [transition] fading in, and fading out.
List<ClusterLabel> _fadingIn(ClusterTransition transition) => [
  for (final label in transition.labels)
    if (label.toOpacity > label.fromOpacity) label,
];
List<ClusterLabel> _fadingOut(ClusterTransition transition) => [
  for (final label in transition.labels)
    if (label.toOpacity < label.fromOpacity) label,
];

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
    expect(_fadingOut(merge), isEmpty);
    expect(_fadingIn(merge).single.spot.count, 2);
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
    expect(_fadingOut(split).single.spot.count, 2);
    expect(_fadingIn(split), isEmpty);
    // The drops part ways: the count stays where the bubble was.
    expect(_fadingOut(split).single.placeAt(1, split.drops).position, _middle);
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
    // The bubble's count had not started to show: nothing to fade out.
    expect(split.labels, isEmpty);
  });

  test('a count half faded in fades out from there when interrupted', () {
    final merge = ClusterTransition.between(
      from: _apart,
      to: _merged,
      now: _start,
    )!;
    // The count fades in over the last 40 %: halfway through it at 80 %.
    final late = _start.add(ClusterTransition.glideDuration * 0.8);

    final split = ClusterTransition.between(
      from: _merged,
      to: _apart,
      now: late,
      running: merge,
    )!;

    final count = _fadingOut(split).single;
    expect(count.fromOpacity, closeTo(0.5, 0.01));
    expect(count.opacityAt(0), closeTo(0.5, 0.01));
    expect(count.opacityAt(1), 0);
  });

  test('a bubble there before and after keeps its count showing', () {
    const far = LatLng(11.60, 104.99);
    const steady = ClusterSpot(
      markerId: 'cluster_9',
      position: far,
      count: 2,
      radius: 17,
      ring: 2.5,
      lift: 2,
    );
    final from = ClusterLayout(
      zoomLevel: 13,
      spotOf: {..._apart.spotOf, 'c': steady, 'd': steady},
    );
    const to = ClusterLayout(
      zoomLevel: 12,
      spotOf: {'a': _bubble, 'b': _bubble, 'c': steady, 'd': steady},
    );

    final merge = ClusterTransition.between(from: from, to: to, now: _start)!;

    final kept = merge.labels.singleWhere((l) => l.spot.position == far);
    for (final p in [0.0, 0.3, 0.5, 0.7, 1.0]) {
      expect(kept.opacityAt(p), 1, reason: 'at $p');
    }
    expect(_fadingIn(merge).single.spot.count, 2);
  });

  test("a bubble's count travels with it into a bigger one", () {
    const pair = ClusterSpot(
      markerId: 'cluster_1',
      position: _a,
      count: 2,
      radius: 17,
      ring: 2.5,
      lift: 2,
    );
    const three = ClusterSpot(
      markerId: 'cluster_2',
      position: _middle,
      count: 3,
      radius: 17,
      ring: 2.5,
      lift: 2,
    );
    final from = ClusterLayout(
      zoomLevel: 13,
      spotOf: {'a': pair, 'b': pair, 'c': _dot('dot_2', _b)},
    );
    const to = ClusterLayout(
      zoomLevel: 12,
      spotOf: {'a': three, 'b': three, 'c': three},
    );

    final merge = ClusterTransition.between(from: from, to: to, now: _start)!;

    final leaving = _fadingOut(merge).single;
    expect(leaving.placeAt(0, merge.drops).position, _a);
    expect(
      leaving.placeAt(0.3, merge.drops).position,
      merge.drops['a']!.positionAt(0.3),
    );
    // The count of three waits where the drops meet.
    expect(_fadingIn(merge).single.placeAt(0.3, merge.drops).position, _middle);
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
    expect(_fadingOut(split), hasLength(1));
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
      expect(_fadingIn(split), hasLength(2));
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

      expect(_fadingOut(merge), hasLength(2));
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
