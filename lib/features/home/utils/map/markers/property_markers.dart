import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'marker_cache.dart';
import 'marker_renderer.dart';
import 'price_tag_layout.dart';

/// Markers for listings on the explore map.
abstract final class PropertyMarkers {
  static const _green = Color(0xFF028752);

  /// The listing green, also used by the merge animation.
  static const green = _green;

  /// Radius of an unselected [greenDot], in logical pixels.
  static const dotRadius = 12.5;

  /// The white ring around a [clusterBubble].
  static const clusterRing = 2.5;

  /// How far above its map position a [clusterBubble]'s circle is drawn,
  /// leaving room for its shadow below.
  static const clusterLift = 2.0;

  /// How wide a [clusterBubble] holding [count] listings is drawn.
  static double clusterDiameter(int count) =>
      count < 10 ? 34.0 : (count < 100 ? 40.0 : 48.0);
  static final _priceCache = MarkerCache();
  static final _clusterCache = MarkerCache();
  static final _priceLayouts = <String, PriceTagLayout>{};

  /// Green dot with a white border. When [isSelected] it grows and gets a
  /// white ring so the listing behind the open card is easy to spot.
  static Future<BitmapDescriptor> greenDot({bool isSelected = false}) {
    const size = 57.0;
    const center = Offset(size / 2, size / 2);
    final radius = isSelected ? 17.0 : dotRadius;

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

  /// Green bubble with the number of listings merged into it. Grows a little
  /// with the count so busy areas stand out.
  static Future<BitmapDescriptor> clusterBubble(int count) {
    final text = count > 999 ? '999+' : '$count';
    return _clusterCache.get(text, () => _renderClusterBubble(count, text));
  }

  static Future<BitmapDescriptor> _renderClusterBubble(int count, String text) {
    final diameter = clusterDiameter(count);
    const shadowRoom = 8.0;
    final size = diameter + shadowRoom;
    final center = Offset(size / 2, size / 2 - clusterLift);
    final label = layoutText(
      text,
      const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );

    return renderMarker(
      width: size,
      height: size,
      draw: (canvas) {
        canvas.drawCircle(
          center.translate(0, 2),
          diameter / 2,
          markerShadowPaint(alpha: 0.18, blur: 4.0),
        );
        canvas.drawCircle(center, diameter / 2, Paint()..color = Colors.white);
        canvas.drawCircle(
          center,
          diameter / 2 - clusterRing,
          Paint()..color = _green,
        );
        label.paint(
          canvas,
          center.translate(-label.width / 2, -label.height / 2),
        );
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
    String newLabel = 'New',
  }) {
    final tag = priceTagLayout(
      price: price,
      isNew: isNew,
      isSelected: isSelected,
      propertyType: propertyType,
      isVisited: isVisited,
      newLabel: newLabel,
    );
    return _priceCache.get(
      _priceKey(price, isNew, isSelected, propertyType, isVisited, newLabel),
      () => _renderPriceTag(tag),
    );
  }

  /// How [priceTag] measures and colours the tag, for drawing it elsewhere.
  static PriceTagLayout priceTagLayout({
    required String price,
    bool isNew = false,
    bool isSelected = false,
    String propertyType = 'Sell',
    bool isVisited = false,
    String newLabel = 'New',
  }) {
    final key = _priceKey(
      price,
      isNew,
      isSelected,
      propertyType,
      isVisited,
      newLabel,
    );
    return _priceLayouts[key] ??= PriceTagLayout.measure(
      price: layoutText(
        price,
        TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 16.0 : 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      newLabel: isNew
          ? layoutText(
              newLabel,
              const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      background: isSelected
          ? _priceColor(propertyType, isVisited).withValues(alpha: 0.8)
          : _priceColor(propertyType, isVisited),
      borderWidth: isSelected ? 2.5 : 1.5,
    );
  }

  static String _priceKey(
    String price,
    bool isNew,
    bool isSelected,
    String propertyType,
    bool isVisited,
    String newLabel,
  ) => 'price-$price-$isNew-$isSelected-$propertyType-$isVisited-$newLabel';

  static Future<BitmapDescriptor> _renderPriceTag(PriceTagLayout tag) {
    // Half the border is drawn outside the body; this room on every side
    // keeps it from being cut off at the bitmap's edges.
    final inset = tag.borderWidth / 2;

    return renderMarker(
      width: (tag.size.width + inset * 2).ceilToDouble(),
      height: (tag.size.height + inset * 2).ceilToDouble(),
      draw: (canvas) {
        canvas.translate(inset, inset);
        canvas.drawRRect(tag.body, Paint()..color = tag.background);
        canvas.drawRRect(
          tag.body,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = tag.borderWidth,
        );
        tag.paintLabels(canvas, Offset.zero);
      },
    );
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
