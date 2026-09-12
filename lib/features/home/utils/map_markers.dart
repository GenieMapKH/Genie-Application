import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DynamicMapMarkers {
  static final Map<int, BitmapDescriptor> _numberedMarkerCache = {};
  static final Map<String, BitmapDescriptor> _textMarkerCache = {};
  static BitmapDescriptor? _selectedVertexCache;
  static BitmapDescriptor? _smallWhiteDotCache;

  /// Clear caches if needed
  static void clearCache() {
    _numberedMarkerCache.clear();
    _textMarkerCache.clear();
    _selectedVertexCache = null;
    _smallWhiteDotCache = null;
  }

  /// Creates a circular marker with a number inside (e.g. for vertices)
  static Future<BitmapDescriptor> createNumberedMarker(int number) async {
    if (_numberedMarkerCache.containsKey(number)) {
      return _numberedMarkerCache[number]!;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 26.0;
    const double pixelRatio = 3.0;

    canvas.scale(pixelRatio, pixelRatio);

    // Draw white circle with shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 1),
      size / 2.5,
      shadowPaint,
    );

    final Paint paint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, paint);

    // Draw text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Color(0xFF6B7280), // Gray text
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily:
              'Inter', // Note: Using default if Inter isn't loaded on Canvas yet
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (size * pixelRatio).toInt(),
      (size * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
    _numberedMarkerCache[number] = descriptor;
    return descriptor;
  }

  /// Creates a pill-shaped marker with text (e.g. for area and lengths)
  static Future<BitmapDescriptor> createTextMarker(
    String text, {
    bool isArea = false,
    double? fontSize,
  }) async {
    final double actualFontSize = fontSize ?? (isArea ? 14.0 : 12.0);
    final String cacheKey =
        '$text-${actualFontSize.toStringAsFixed(1)}-$isArea';
    if (_textMarkerCache.containsKey(cacheKey)) {
      return _textMarkerCache[cacheKey]!;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double pixelRatio = 3.0;

    canvas.scale(pixelRatio, pixelRatio);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isArea ? const Color(0xFF4B5563) : const Color(0xFF6B7280),
          fontSize: actualFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double scaleRatio = (actualFontSize / 14.0).clamp(0.6, 1.0);
    final double paddingHorizontal = (isArea ? 12.0 : 8.0) * scaleRatio;
    final double paddingVertical = (isArea ? 6.0 : 4.0) * scaleRatio;
    final double width = textPainter.width + paddingHorizontal * 2;
    final double height = textPainter.height + paddingVertical * 2;

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final RRect shadowRRect = RRect.fromLTRBR(
      0,
      2,
      width,
      height + 2,
      const Radius.circular(24.0),
    );
    canvas.drawRRect(shadowRRect, shadowPaint);

    // Draw white background
    final Paint paint = Paint()..color = Colors.white;
    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      width,
      height,
      const Radius.circular(24.0),
    );
    canvas.drawRRect(rrect, paint);

    // Draw text
    textPainter.paint(canvas, Offset(paddingHorizontal, paddingVertical));

    // Add extra padding to canvas size so shadows aren't clipped
    final int canvasWidth = (width + 8).toInt();
    final int canvasHeight = (height + 8).toInt();

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (canvasWidth * pixelRatio).toInt(),
      (canvasHeight * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: canvasWidth.toDouble(),
      height: canvasHeight.toDouble(),
    );
    _textMarkerCache[cacheKey] = descriptor;
    return descriptor;
  }

  /// Creates a green dot marker with a white border and drop shadow.
  ///
  /// When [isSelected] the dot grows and gains a white ring so the property
  /// tied to the open card is identifiable at a glance.
  static Future<BitmapDescriptor> createGreenDotMarker({
    bool isSelected = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 57.0;
    const double pixelRatio = 3.0;
    final double radius = isSelected ? 17.0 : 12.5;

    canvas.scale(pixelRatio, pixelRatio);

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    // Draw shadow offset down by 4
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 4),
      radius,
      shadowPaint,
    );

    if (isSelected) {
      // White halo ring behind the dot
      final Paint haloPaint = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(size / 2, size / 2), radius, haloPaint);
    }

    // Draw green circle
    final Paint paint = Paint()..color = const Color(0xFF028752);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      isSelected ? radius - 3.5 : radius,
      paint,
    );

    // Draw border
    final Paint borderPaint = Paint()
      ..color = isSelected ? Colors.white : const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.0;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      isSelected ? radius - 1.75 : 12.0,
      borderPaint,
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (size * pixelRatio).toInt(),
      (size * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
  }

  /// Creates the green "New" pill shown above recently listed properties.
  static Future<BitmapDescriptor> createNewBadgeMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double pixelRatio = 3.0;

    canvas.scale(pixelRatio, pixelRatio);

    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: 'New',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double width = textPainter.width + 20;
    final double height = textPainter.height + 10;

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 2, width, height + 2, const Radius.circular(24.0)),
      shadowPaint,
    );

    // Draw green pill
    final Paint paint = Paint()..color = const Color(0xFF028752);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, width, height, const Radius.circular(24.0)),
      paint,
    );

    textPainter.paint(canvas, const Offset(10, 5));

    final int canvasWidth = (width + 8).toInt();
    final int canvasHeight = (height + 8).toInt();

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (canvasWidth * pixelRatio).toInt(),
      (canvasHeight * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: canvasWidth.toDouble(),
      height: canvasHeight.toDouble(),
    );
  }

  /// Creates a price marker, shaped like a pill or rounded rectangle with "New" badge.
  static Future<BitmapDescriptor> createPriceMarker({
    required String price,
    bool isNew = false,
    bool isSelected = false,
    String propertyType = 'Sell',
    bool isVisited = false,
  }) async {
    final String cacheKey =
        'price-$price-$isNew-$isSelected-$propertyType-$isVisited';
    if (_textMarkerCache.containsKey(cacheKey)) {
      return _textMarkerCache[cacheKey]!;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double pixelRatio = 3.0;

    canvas.scale(pixelRatio, pixelRatio);

    final TextPainter pricePainter = TextPainter(
      text: TextSpan(
        text: price,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 16.0 : 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    pricePainter.layout();

    TextPainter? newPainter;
    if (isNew) {
      newPainter = TextPainter(
        text: const TextSpan(
          text: 'New',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      newPainter.layout();
    }

    final double paddingHorizontal = isNew ? 12.0 : 10.0;
    final double paddingVertical = isNew ? 8.0 : 6.0;

    double contentWidth = pricePainter.width;
    double contentHeight = pricePainter.height;

    if (isNew && newPainter != null) {
      contentWidth = [
        pricePainter.width,
        newPainter.width,
      ].reduce((a, b) => a > b ? a : b);
      contentHeight += newPainter.height + 2; // spacing
    }

    final double width = contentWidth + paddingHorizontal * 2;
    final double height = contentHeight + paddingVertical * 2;
    final double radius = isNew ? 10.0 : height / 2; // Pill shape for non-new

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    final RRect shadowRRect = RRect.fromLTRBR(
      0,
      2,
      width,
      height + 2,
      Radius.circular(radius),
    );
    canvas.drawRRect(shadowRRect, shadowPaint);

    Color getBaseColor() {
      if (propertyType.toLowerCase() == 'sell') {
        return isVisited ? const Color(0xFF6AE0B1) : const Color(0xFF028752);
      } else if (propertyType.toLowerCase() == 'rent') {
        return isVisited ? const Color(0xFFEFB6B8) : const Color(0xFFE5484D);
      } else if (propertyType.toLowerCase() == 'to let') {
        return isVisited ? const Color(0xFFEFDDB5) : const Color(0xFFDBA122);
      }
      return isVisited ? const Color(0xFF6AE0B1) : const Color(0xFF028752);
    }

    final Color bgColor = isSelected
        ? getBaseColor().withValues(alpha: 0.8)
        : getBaseColor();

    // Draw background
    final Paint paint = Paint()..color = bgColor;
    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      width,
      height,
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, paint);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // Draw text
    double currentY = paddingVertical;
    if (isNew && newPainter != null) {
      newPainter.paint(
        canvas,
        Offset((width - newPainter.width) / 2, currentY),
      );
      currentY += newPainter.height + 2;
    }
    pricePainter.paint(
      canvas,
      Offset((width - pricePainter.width) / 2, currentY),
    );

    final int canvasWidth = (width + 8).toInt();
    final int canvasHeight = (height + 8).toInt();

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (canvasWidth * pixelRatio).toInt(),
      (canvasHeight * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: canvasWidth.toDouble(),
      height: canvasHeight.toDouble(),
    );
    _textMarkerCache[cacheKey] = descriptor;
    return descriptor;
  }

  /// Creates a circular edit marker with a pen icon
  static Future<BitmapDescriptor> createEditMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 50.0;
    const double pixelRatio = 3.0;

    canvas.scale(pixelRatio, pixelRatio);

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 2),
      size / 2.5,
      shadowPaint,
    );

    // Draw blue circle
    final Paint paint = Paint()..color = const Color(0xFF3E49C7);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, paint);

    // Draw white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      borderPaint,
    );

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
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (size * pixelRatio).toInt(),
      (size * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
  }

  /// Creates a highlighted vertex marker for selected edit handles (centered anchor 0.5, 0.5)
  static Future<BitmapDescriptor> createSelectedVertexMarker() async {
    if (_selectedVertexCache != null) return _selectedVertexCache!;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 32.0;
    const double pixelRatio = 3.0;

    canvas.scale(pixelRatio, pixelRatio);

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 1),
      size / 2.5,
      shadowPaint,
    );

    // White ring
    final Paint whiteRing = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, whiteRing);

    // Red inner dot
    final Paint accentFill = Paint()..color = const Color(0xFFE5484D);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 3.8, accentFill);

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (size * pixelRatio).toInt(),
      (size * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
    _selectedVertexCache = descriptor;
    return descriptor;
  }

  /// Creates a small white dot marker
  static Future<BitmapDescriptor> createSmallWhiteDotMarker() async {
    if (_smallWhiteDotCache != null) return _smallWhiteDotCache!;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 24.0;
    const double pixelRatio = 3.0;

    canvas.scale(pixelRatio, pixelRatio);

    // Draw shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 1),
      size / 3,
      shadowPaint,
    );

    // Draw white circle
    final Paint paint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 3, paint);

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      (size * pixelRatio).toInt(),
      (size * pixelRatio).toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
    );
    _smallWhiteDotCache = descriptor;
    return descriptor;
  }
}
