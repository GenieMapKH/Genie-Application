import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'marker_renderer.dart';

/// Markers for listings on the explore map.
abstract final class PropertyMarkers {
  static const _green = Color(0xFF028752);
  static final Map<String, BitmapDescriptor> _priceCache = {};

  /// Green dot with a white border. When [isSelected] it grows and gets a
  /// white ring so the listing behind the open card is easy to spot.
  static Future<BitmapDescriptor> greenDot({bool isSelected = false}) {
    const size = 57.0;
    const center = Offset(size / 2, size / 2);
    final radius = isSelected ? 17.0 : 12.5;

    return renderMarker(
      width: size,
      height: size,
      draw: (canvas) {
        canvas.drawCircle(
          center.translate(0, 4),
          radius,
          markerShadowPaint(alpha: 0.16, blur: 8.0),
        );

        if (isSelected) {
          canvas.drawCircle(center, radius, Paint()..color = Colors.white);
        }

        canvas.drawCircle(
          center,
          isSelected ? radius - 3.5 : radius,
          Paint()..color = _green,
        );

        canvas.drawCircle(
          center,
          isSelected ? radius - 1.75 : 12.0,
          Paint()
            ..color = isSelected ? Colors.white : const Color(0xFFE5E7EB)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 3.0 : 1.0,
        );
      },
    );
  }

  /// Green "New" pill shown above recently listed properties.
  static Future<BitmapDescriptor> newBadge() {
    final label = layoutText(
      'New',
      const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
    final pillWidth = label.width + 20;
    final pillHeight = label.height + 10;

    return renderMarker(
      width: (pillWidth + 8).toInt().toDouble(),
      height: (pillHeight + 8).toInt().toDouble(),
      draw: (canvas) {
        const radius = Radius.circular(24.0);
        canvas.drawRRect(
          RRect.fromLTRBR(0, 2, pillWidth, pillHeight + 2, radius),
          markerShadowPaint(alpha: 0.18, blur: 4.0),
        );
        canvas.drawRRect(
          RRect.fromLTRBR(0, 0, pillWidth, pillHeight, radius),
          Paint()..color = _green,
        );
        label.paint(canvas, const Offset(10, 5));
      },
    );
  }

  /// Price tag coloured by listing type; dimmed once the user has visited it.
  /// A "New" label is stacked above the price for recent listings.
  static Future<BitmapDescriptor> priceTag({
    required String price,
    bool isNew = false,
    bool isSelected = false,
    String propertyType = 'Sell',
    bool isVisited = false,
  }) async {
    final cacheKey = 'price-$price-$isNew-$isSelected-$propertyType-$isVisited';
    final cached = _priceCache[cacheKey];
    if (cached != null) return cached;

    final priceLabel = layoutText(
      price,
      TextStyle(
        color: Colors.white,
        fontSize: isSelected ? 16.0 : 14.0,
        fontWeight: FontWeight.bold,
      ),
    );
    final newLabel = isNew
        ? layoutText(
            'New',
            const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          )
        : null;

    const labelGap = 2.0;
    final paddingX = isNew ? 12.0 : 10.0;
    final paddingY = isNew ? 8.0 : 6.0;

    var contentWidth = priceLabel.width;
    var contentHeight = priceLabel.height;
    if (newLabel != null) {
      contentWidth = contentWidth > newLabel.width
          ? contentWidth
          : newLabel.width;
      contentHeight += newLabel.height + labelGap;
    }

    final width = contentWidth + paddingX * 2;
    final height = contentHeight + paddingY * 2;
    final radius = Radius.circular(isNew ? 10.0 : height / 2);

    final baseColor = _priceColor(propertyType, isVisited);
    final background = isSelected
        ? baseColor.withValues(alpha: 0.8)
        : baseColor;

    final marker = await renderMarker(
      width: (width + 8).toInt().toDouble(),
      height: (height + 8).toInt().toDouble(),
      draw: (canvas) {
        canvas.drawRRect(
          RRect.fromLTRBR(0, 2, width, height + 2, radius),
          markerShadowPaint(alpha: 0.18, blur: 4.0),
        );

        final body = RRect.fromLTRBR(0, 0, width, height, radius);
        canvas.drawRRect(body, Paint()..color = background);
        canvas.drawRRect(
          body,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 2.5 : 1.5,
        );

        var y = paddingY;
        if (newLabel != null) {
          newLabel.paint(canvas, Offset((width - newLabel.width) / 2, y));
          y += newLabel.height + labelGap;
        }
        priceLabel.paint(canvas, Offset((width - priceLabel.width) / 2, y));
      },
    );
    return _priceCache[cacheKey] = marker;
  }

  static Color _priceColor(String propertyType, bool isVisited) {
    switch (propertyType.toLowerCase()) {
      case 'rent':
        return isVisited ? const Color(0xFFEFB6B8) : const Color(0xFFE5484D);
      case 'to let':
        return isVisited ? const Color(0xFFEFDDB5) : const Color(0xFFDBA122);
      default: // 'sell' and anything unknown
        return isVisited ? const Color(0xFF6AE0B1) : _green;
    }
  }
}
