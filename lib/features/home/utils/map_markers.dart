import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DynamicMapMarkers {
  /// Creates a circular marker with a number inside (e.g. for vertices)
  static Future<BitmapDescriptor> createNumberedMarker(int number) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 60.0;
    
    // Draw white circle with shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 2), size / 2.5, shadowPaint);

    final Paint paint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, paint);

    // Draw text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Color(0xFF6B7280), // Gray text
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter', // Note: Using default if Inter isn't loaded on Canvas yet
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
  }

  /// Creates a pill-shaped marker with text (e.g. for area and lengths)
  static Future<BitmapDescriptor> createTextMarker(String text, {bool isArea = false}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isArea ? const Color(0xFF4B5563) : const Color(0xFF6B7280),
          fontSize: isArea ? 22 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double paddingHorizontal = 16.0;
    final double paddingVertical = 8.0;
    final double width = textPainter.width + paddingHorizontal * 2;
    final double height = textPainter.height + paddingVertical * 2;
    
    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final RRect shadowRRect = RRect.fromLTRBR(
      0, 2, width, height + 2,
      const Radius.circular(24.0),
    );
    canvas.drawRRect(shadowRRect, shadowPaint);

    // Draw white background
    final Paint paint = Paint()..color = Colors.white;
    final RRect rrect = RRect.fromLTRBR(
      0, 0, width, height,
      const Radius.circular(24.0),
    );
    canvas.drawRRect(rrect, paint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(paddingHorizontal, paddingVertical),
    );

    // Add extra padding to canvas size so shadows aren't clipped
    final int canvasWidth = (width + 8).toInt();
    final int canvasHeight = (height + 8).toInt();

    final ui.Image img = await pictureRecorder.endRecording().toImage(canvasWidth, canvasHeight);
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: canvasWidth.toDouble(),
      height: canvasHeight.toDouble(),
    );
  }

  /// Creates a green dot marker with a white border and drop shadow
  static Future<BitmapDescriptor> createGreenDotMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 57.0;

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    // Draw shadow offset down by 4
    canvas.drawCircle(const Offset(size / 2, size / 2 + 4), 12.5, shadowPaint);

    // Draw green circle
    final Paint paint = Paint()..color = const Color(0xFF028752);
    canvas.drawCircle(const Offset(size / 2, size / 2), 12.5, paint);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(const Offset(size / 2, size / 2), 12.0, borderPaint);

    final ui.Image img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
  }

  /// Creates a circular edit marker with a pen icon
  static Future<BitmapDescriptor> createEditMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 50.0;
    
    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 2), size / 2.5, shadowPaint);

    // Draw blue circle
    final Paint paint = Paint()..color = const Color(0xFF3E49C7);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, paint);
    
    // Draw white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, borderPaint);

    // Draw Edit Icon
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.edit.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: Icons.edit.fontFamily,
          package: Icons.edit.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
  }
}

