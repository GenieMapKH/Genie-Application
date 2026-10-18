import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/utils/map/cluster_layout.dart';
import 'package:genie/features/home/utils/map/cluster_transition.dart';
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
    final halfway = _start.add(ClusterTransition.duration ~/ 2);

    final split = ClusterTransition.between(
      from: _merged,
      to: _apart,
      now: halfway,
      running: merge,
    )!;

    final t = ClusterTransition.curve.transform(0.5);
    expect(split.drops['a']!.from, merge.drops['a']!.positionAt(t));
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
}
