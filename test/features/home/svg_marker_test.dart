import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/home/utils/map/svg_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the drawing pin is smaller and rendered at triple resolution',
    () async {
      final pin = await getSvgMarker('assets/icons/pin.svg') as BytesMapBitmap;
      expect(pin.width, 34);
      expect(pin.height, closeTo(59.16, 0.01));
      final codec = await ui.instantiateImageCodec(pin.byteData);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 102);
      expect(frame.image.height, 177);
      frame.image.dispose();
      codec.dispose();
    },
  );
}
