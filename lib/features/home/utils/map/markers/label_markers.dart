import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'marker_cache.dart';
import 'marker_renderer.dart';

/// White pill with a text label, e.g. an edge length or the polygon area.
abstract final class LabelMarkers {
  // A dragged corner makes a new area label on almost every move, so old
  // labels are dropped.
  static final _cache = MarkerCache(maxEntries: 300);

  static Future<BitmapDescriptor> text(
    String text, {
    bool isArea = false,
    double? fontSize,
  }) {
    final size = fontSize ?? (isArea ? 14.0 : 12.0);
    final cacheKey = '$text-${size.toStringAsFixed(1)}-$isArea';
    return _cache.get(cacheKey, () => _render(text, size, isArea));
  }

  /// The marker image's size in logical px, as [text] draws it; what the map
  /// needs to keep labels from overlapping.
  static Size sizeOf(String text, {bool isArea = false, double? fontSize}) {
    return _Pill(text, fontSize ?? (isArea ? 14.0 : 12.0), isArea).canvas;
  }

  static Future<BitmapDescriptor> _render(
    String text,
    double size,
    bool isArea,
  ) {
    final pill = _Pill(text, size, isArea);
    return renderMarker(
      width: pill.canvas.width,
      height: pill.canvas.height,
      draw: (canvas) {
        const radius = Radius.circular(24.0);
        final width = pill.width;
        final height = pill.height;
        canvas.drawRRect(
          RRect.fromLTRBR(0, 2, width, height + 2, radius),
          markerShadowPaint(alpha: 0.15, blur: 4.0),
        );
        canvas.drawRRect(
          RRect.fromLTRBR(0, 0, width, height, radius),
          Paint()..color = Colors.white,
        );
        pill.label.paint(canvas, Offset(pill.paddingX, pill.paddingY));
      },
    );
  }
}

/// The text and measurements of one label pill.
class _Pill {
  final TextPainter label;
  final double paddingX;
  final double paddingY;

  factory _Pill(String text, double size, bool isArea) {
    // Smaller text gets proportionally smaller padding.
    final scale = (size / 14.0).clamp(0.6, 1.0);
    return _Pill._(
      layoutText(
        text,
        TextStyle(
          color: isArea ? const Color(0xFF4B5563) : const Color(0xFF6B7280),
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      (isArea ? 12.0 : 8.0) * scale,
      (isArea ? 6.0 : 4.0) * scale,
    );
  }

  _Pill._(this.label, this.paddingX, this.paddingY);

  double get width => label.width + paddingX * 2;
  double get height => label.height + paddingY * 2;

  /// Extra room so the shadow is not clipped.
  Size get canvas =>
      Size((width + 8).toInt().toDouble(), (height + 8).toInt().toDouble());
}
