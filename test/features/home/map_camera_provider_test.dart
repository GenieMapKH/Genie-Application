import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/home/presentation/providers/map_camera_provider.dart';
import 'package:genie/features/home/presentation/providers/map_state_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('moving the camera does not notify map state listeners', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    var mapStateNotifications = 0;
    container.listen(mapStateProvider, (_, _) => mapStateNotifications++);

    final camera = container.read(mapCameraProvider.notifier);
    for (var i = 0; i < 120; i++) {
      camera.state = MapCamera(
        center: LatLng(11.5 + i * 0.0001, 104.9),
        zoom: 14 + i * 0.01,
      );
    }

    expect(mapStateNotifications, 0);
    expect(container.read(mapCameraProvider).zoom, closeTo(15.19, 0.001));
  });

  test('map state changes do not touch the camera', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(mapCameraProvider);
    container.read(mapStateProvider.notifier).toggleSkin();

    expect(container.read(mapStateProvider).currentSkin, MapSkin.satellite);
    expect(identical(container.read(mapCameraProvider), before), isTrue);
  });
}
