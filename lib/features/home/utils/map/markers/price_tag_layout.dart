import 'package:flutter/painting.dart';

import 'price_tag_pin.dart';

/// A listing's price tag measured and coloured, ready to paint.
///
/// Shared by the map marker and the merge animation, so both draw the very
/// same tag.
class PriceTagLayout {
  final TextPainter price;

  /// The "New" stacked above the price of a recent listing.
  final TextPainter? newLabel;

  /// The tag's body; its white [borderWidth] is centred on the body's edge.
  final Size size;
  final Radius radius;
  final Color background;
  final double borderWidth;

  final double _paddingY;

  static const _labelGap = 2.0;

  const PriceTagLayout({
    required this.price,
    required this.newLabel,
    required this.size,
    required this.radius,
    required this.background,
    required this.borderWidth,
    required double paddingY,
  }) : _paddingY = paddingY;

  /// Measures a tag around [price] (and [newLabel], when given).
  factory PriceTagLayout.measure({
    required TextPainter price,
    TextPainter? newLabel,
    required Color background,
    required double borderWidth,
  }) {
    final isNew = newLabel != null;
    final paddingX = isNew ? 12.0 : 10.0;
    final paddingY = isNew ? 8.0 : 6.0;

    var contentWidth = price.width;
    var contentHeight = price.height;
    if (newLabel != null) {
      if (newLabel.width > contentWidth) contentWidth = newLabel.width;
      contentHeight += newLabel.height + _labelGap;
    }

    final height = contentHeight + paddingY * 2;
    return PriceTagLayout(
      price: price,
      newLabel: newLabel,
      size: Size(contentWidth + paddingX * 2, height),
      radius: Radius.circular(isNew ? 10.0 : 8.0),
      background: background,
      borderWidth: borderWidth,
      paddingY: paddingY,
    );
  }

  /// The body and its white border together.
  Size get outerSize =>
      Size(size.width + borderWidth, size.height + borderWidth);

  /// How far above the listing the tag's centre is, its [PriceTagPin] point
  /// on the listing.
  double get lift => outerSize.height / 2 + PriceTagPin.tail;

  /// The tag's outer edge, with its top-left corner at [origin].
  RRect outline(Offset origin) => RRect.fromRectAndRadius(
    origin & outerSize,
    radius + Radius.circular(borderWidth / 2),
  );

  /// Paints the labels inside a body whose top-left corner is at [origin].
  void paintLabels(Canvas canvas, Offset origin) {
    var y = origin.dy + _paddingY;
    final label = newLabel;
    if (label != null) {
      label.paint(
        canvas,
        Offset(origin.dx + (size.width - label.width) / 2, y),
      );
      y += label.height + _labelGap;
    }
    price.paint(canvas, Offset(origin.dx + (size.width - price.width) / 2, y));
  }
}
