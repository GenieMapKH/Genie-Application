import 'package:flutter/material.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'marker_renderer.dart';

/// Round handles shown while drawing or editing a property boundary.
abstract final class VertexMarkers {
  static final Map<int, BitmapDescriptor> _numberedCache = {};
  static BitmapDescriptor? _selectedCache;
  static BitmapDescriptor? _smallWhiteDotCache;

  /// White circle with the vertex number inside.
  static Future<BitmapDescriptor> numbered(int number) async {
    final cached = _numberedCache[number];
    if (cached != null) return cached;

    const size = 26.0;
    const center = Offset(size / 2, size / 2);

    final marker = await renderMarker(
      width: size,
      height: size,
      draw: (canvas) {
        canvas.drawCircle(
          center.translate(0, 1),
          size / 2.5,
          markerShadowPaint(alpha: 0.15, blur: 2.0),
        );
        canvas.drawCircle(center, size / 2.5, Paint()..color = Colors.white);

        // 'Inter' falls back to the default font if it is not loaded yet.
        final label = layoutText(
          number.toString(),
          const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        );
        label.paint(
          canvas,
          Offset(size / 2 - label.width / 2, size / 2 - label.height / 2),
        );
      },
    );
    return _numberedCache[number] = marker;
  }

  /// Highlighted handle for the vertex being dragged (red dot in a white ring).
  static Future<BitmapDescriptor> selected() async {
    final cached = _selectedCache;
    if (cached != null) return cached;

    const size = 32.0;
    const center = Offset(size / 2, size / 2);

    final marker = await renderMarker(
      width: size,
      height: size,
      draw: (canvas) {
        canvas.drawCircle(
          center.translate(0, 1),
          size / 2.5,
          markerShadowPaint(alpha: 0.25, blur: 3.0),
        );
        canvas.drawCircle(center, size / 2.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          center,
          size / 3.8,
          Paint()..color = const Color(0xFFE5484D),
        );
      },
    );
    return _selectedCache = marker;
  }

  /// Small white dot, e.g. the midpoint between two vertices.
  static Future<BitmapDescriptor> smallWhiteDot() async {
    final cached = _smallWhiteDotCache;
    if (cached != null) return cached;

    const size = 24.0;
    const center = Offset(size / 2, size / 2);

    final marker = await renderMarker(
      width: size,
      height: size,
      draw: (canvas) {
        canvas.drawCircle(
          center.translate(0, 1),
          size / 3,
          markerShadowPaint(alpha: 0.15, blur: 2.0),
        );
        canvas.drawCircle(center, size / 3, Paint()..color = Colors.white);
      },
    );
    return _smallWhiteDotCache = marker;
  }

  /// Blue circle with a white pen icon: the "edit this boundary" button.
  static Future<BitmapDescriptor> edit() {
    const size = 50.0;
    const center = Offset(size / 2, size / 2);

    return renderMarker(
      width: size,
      height: size,
      draw: (canvas) {
        canvas.drawCircle(
          center.translate(0, 2),
          size / 2.5,
          markerShadowPaint(alpha: 0.15, blur: 4.0),
        );
        canvas.drawCircle(
          center,
          size / 2.5,
          Paint()..color = AppColors.light.primary,
        );
        canvas.drawCircle(
          center,
          size / 2.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );

        final icon = layoutText(
          String.fromCharCode(Icons.edit.codePoint),
          TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: Icons.edit.fontFamily,
            package: Icons.edit.fontPackage,
          ),
        );
        icon.paint(
          canvas,
          Offset(size / 2 - icon.width / 2, size / 2 - icon.height / 2),
        );
      },
    );
  }
}
