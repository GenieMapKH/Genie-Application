import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Map markers are drawn at 3x so they stay sharp on high-density screens.
const double _pixelRatio = 3.0;

/// Draws a marker with [draw] and returns it as a map bitmap.
///
/// [draw] works in logical pixels on a canvas of [width] x [height].
Future<BitmapDescriptor> renderMarker({
  required double width,
  required double height,
  required void Function(Canvas canvas) draw,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(_pixelRatio, _pixelRatio);
  draw(canvas);

  final image = await recorder.endRecording().toImage(
    (width * _pixelRatio).toInt(),
    (height * _pixelRatio).toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.bytes(
    data!.buffer.asUint8List(),
    width: width,
    height: height,
  );
}

/// Soft black paint used for every marker's drop shadow.
Paint markerShadowPaint({required double alpha, required double blur}) {
  return Paint()
    ..color = Colors.black.withValues(alpha: alpha)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
}

/// Single-line text laid out and ready to paint.
TextPainter layoutText(String text, TextStyle style) {
  return TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
}
