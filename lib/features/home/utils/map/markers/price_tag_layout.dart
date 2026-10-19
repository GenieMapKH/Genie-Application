import 'package:flutter/painting.dart';

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
      radius: Radius.circular(isNew ? 10.0 : height / 2),
      background: background,
      borderWidth: borderWidth,
      paddingY: paddingY,
    );
  }

  /// The body with its top-left corner at the origin.
  RRect get body => RRect.fromRectAndRadius(Offset.zero & size, radius);

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
