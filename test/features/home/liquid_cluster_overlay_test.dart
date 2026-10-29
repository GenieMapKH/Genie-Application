import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/home/presentation/providers/map_camera_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/map/liquid/liquid_cluster_overlay.dart';
import 'package:tilomnov/features/home/utils/map/cluster_layout.dart';
import 'package:tilomnov/features/home/utils/map/cluster_transition.dart';
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

    await tester.pump(ClusterTransition.glideDuration ~/ 2);
    expect(events, isEmpty);

    await tester.pump(ClusterTransition.glideDuration);
    expect(events, ['landed']);
    double opacity() => tester.widget<Opacity>(find.byType(Opacity)).opacity;
    expect(opacity(), 1);

    // Fades into the map's own markers rather than cutting to them.
    await tester.pump(
      LiquidClusterOverlay.hold + LiquidClusterOverlay.fadeOut ~/ 2,
    );
    expect(events, ['landed']);
    expect(opacity(), inExclusiveRange(0, 1));

    await tester.pump(LiquidClusterOverlay.fadeOut);
    expect(events, ['landed', 'done']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaves at once when the map moves after landing', (
    tester,
  ) async {
    final events = <String>[];
    var camera = const MapCamera(center: _center, zoom: 12.5);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LiquidClusterOverlay(
          transition: _merge(),
          readCamera: () => camera,
          onLanded: () => events.add('landed'),
          onDone: () => events.add('done'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(ClusterTransition.glideDuration);
    expect(events, ['landed']);

    camera = const MapCamera(center: LatLng(11.56, 104.93), zoom: 12.5);
    await tester.pump(const Duration(milliseconds: 16));
    expect(events, ['landed', 'done']);
  });
}
