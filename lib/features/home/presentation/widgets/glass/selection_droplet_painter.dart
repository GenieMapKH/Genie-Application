import 'package:flutter/material.dart';

/// The drop of tinted glass under the open tab of a glass bar. It is painted
/// on the bar's own glass, never as glass of its own (glass on glass would
/// blur the screen twice), and stretches along its path while it moves, like
/// a liquid drop.
class SelectionDropletPainter extends CustomPainter {
  /// The droplet's place, counted in tabs; its velocity sets the stretch.
  final AnimationController position;
  final int count;
  final Color color;
  final Color rim;

  SelectionDropletPainter({
    required this.position,
    required this.count,
    required this.color,
    required this.rim,
  }) : super(repaint: position);

  /// The inset between the droplet and the bar's edge.
  static const _inset = 5.0;

  /// Tabs per second at which the droplet is stretched the most.
  static const _fullStretchSpeed = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / count;
    final stretch = (position.velocity.abs() / _fullStretchSpeed).clamp(
      0.0,
      1.0,
    );
    final width = (slot - _inset * 2) * (1 + 0.22 * stretch);
    final height = (size.height - _inset * 2) * (1 - 0.08 * stretch);
    final centre = Offset(slot * (position.value + 0.5), size.height / 2);

    // Overshooting the first or last tab presses the drop against the edge
    // instead of letting it leave the bar.
    final left = (centre.dx - width / 2).clamp(_inset, size.width - _inset);
    final right = (centre.dx + width / 2).clamp(_inset, size.width - _inset);
    if (right - left < 1) return;

    final rect = Rect.fromLTRB(
      left,
      centre.dy - height / 2,
      right,
      centre.dy + height / 2,
    );
    final drop = RRect.fromRectAndRadius(rect, Radius.circular(height / 2));

    canvas.drawRRect(drop, Paint()..color = color);
    canvas.drawRRect(
      drop.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rim, rim.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(SelectionDropletPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.count != count ||
      oldDelegate.color != color ||
      oldDelegate.rim != rim;
}
