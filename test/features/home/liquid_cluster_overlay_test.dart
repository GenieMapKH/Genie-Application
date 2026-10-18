import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/widgets/map/liquid/liquid_cluster_overlay.dart';
import 'package:genie/features/home/utils/map/cluster_layout.dart';
import 'package:genie/features/home/utils/map/cluster_transition.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _center = LatLng(11.55, 104.92);

ClusterTransition _merge() {
  ClusterSpot dot(String id, double lng) => ClusterSpot(
    markerId: id,
    position: LatLng(11.55, lng),
    count: 1,
    radius: 12.5,
    ring: 1,
  );
  const bubble = ClusterSpot(
    markerId: 'cluster_0',
    position: _center,
    count: 2,
    radius: 17,
    ring: 2.5,
  );
  return ClusterTransition.between(
    from: ClusterLayout(
      zoomLevel: 13,
      spotOf: {'a': dot('dot_0', 104.9199), 'b': dot('dot_1', 104.9201)},
    ),
    to: const ClusterLayout(zoomLevel: 12, spotOf: {'a': bubble, 'b': bubble}),
    now: DateTime.now(),
  )!;
}

void main() {
  testWidgets('hands the dots back to the map, then leaves', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LiquidClusterOverlay(
          transition: _merge(),
          readCamera: () => const MapCamera(center: _center, zoom: 12.5),
          onLanded: () => events.add('landed'),
          onDone: () => events.add('done'),
        ),
      ),
    );

    await tester.pump(ClusterTransition.duration ~/ 2);
    expect(events, isEmpty);

    await tester.pump(ClusterTransition.duration);
    expect(events, ['landed']);

    await tester.pump(LiquidClusterOverlay.handover);
    expect(events, ['landed', 'done']);
    expect(tester.takeException(), isNull);
  });
}
