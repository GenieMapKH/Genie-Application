import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/property/utils/watermark_photo.dart';

Future<Uint8List> _solidPng(int width, int height, ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

Future<(int, ByteData)> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return (image.width, pixels!);
}

int _red(ByteData pixels, int width, int x, int y) =>
    pixels.getUint8((y * width + x) * 4);

void main() {
  testWidgets('draws the logo faintly in the middle, keeping the size', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final photo = await _solidPng(200, 100, const ui.Color(0xFF000000));
      final logo = await _solidPng(40, 40, const ui.Color(0xFFFFFFFF));

      final marked = await watermarkPhoto(
        photo: photo,
        logo: logo,
        widthFactor: 0.3,
        opacity: 0.35,
      );

      final (width, pixels) = await _decode(marked!);
      expect(width, 200);
      final centre = _red(pixels, width, 100, 50);
      expect(centre, inInclusiveRange(80, 100)); // ~35% of white
      expect(_red(pixels, width, 5, 5), 0); // corner untouched
    });
  });

  testWidgets('gives null for bytes that are not a picture', (tester) async {
    await tester.runAsync(() async {
      final logo = await _solidPng(4, 4, const ui.Color(0xFFFFFFFF));
      final marked = await watermarkPhoto(
        photo: Uint8List.fromList([1, 2, 3]),
        logo: logo,
        widthFactor: 0.3,
        opacity: 0.35,
      );
      expect(marked, isNull);
    });
  });
}
