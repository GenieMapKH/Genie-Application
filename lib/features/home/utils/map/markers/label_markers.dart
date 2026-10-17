import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'marker_renderer.dart';

/// White pill with a text label, e.g. an edge length or the polygon area.
abstract final class LabelMarkers {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> text(
    String text, {
    bool isArea = false,
    double? fontSize,
  }) async {
    final size = fontSize ?? (isArea ? 14.0 : 12.0);
    final cacheKey = '$text-${size.toStringAsFixed(1)}-$isArea';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final label = layoutText(
      text,
      TextStyle(
        color: isArea ? const Color(0xFF4B5563) : const Color(0xFF6B7280),
        fontSize: size,
        fontWeight: FontWeight.bold,
      ),
    );

    // Smaller text gets proportionally smaller padding.
    final scale = (size / 14.0).clamp(0.6, 1.0);
    final paddingX = (isArea ? 12.0 : 8.0) * scale;
    final paddingY = (isArea ? 6.0 : 4.0) * scale;
    final pillWidth = label.width + paddingX * 2;
    final pillHeight = label.height + paddingY * 2;

    // Extra room so the shadow is not clipped.
    final canvasWidth = (pillWidth + 8).toInt().toDouble();
    final canvasHeight = (pillHeight + 8).toInt().toDouble();

    final marker = await renderMarker(
      width: canvasWidth,
      height: canvasHeight,
      draw: (canvas) {
        const radius = Radius.circular(24.0);
        canvas.drawRRect(
          RRect.fromLTRBR(0, 2, pillWidth, pillHeight + 2, radius),
          markerShadowPaint(alpha: 0.15, blur: 4.0),
        );
        canvas.drawRRect(
          RRect.fromLTRBR(0, 0, pillWidth, pillHeight, radius),
          Paint()..color = Colors.white,
        );
        label.paint(canvas, Offset(paddingX, paddingY));
      },
    );
    return _cache[cacheKey] = marker;
  }
}
