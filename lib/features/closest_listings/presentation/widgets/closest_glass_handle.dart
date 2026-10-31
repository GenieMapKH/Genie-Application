import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/closest_listings/presentation/closest_liquid_shape.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_surface.dart';

/// The pull-up list's resting handle as a small pane of glass, drawn over
/// the sheet's top while the glass navigation bar is on. As the sheet is
/// pulled the panel's drop hangs from it, and it stretches and fills with
/// the panel's colour until it is the panel's own top edge, its grip the
/// panel's grip ([ClosestLiquidShape]).
///
/// Draws only: touches go through to the sheet's own handle underneath.
class ClosestGlassHandle extends StatelessWidget {
  /// How far the sheet is pulled out of it, 0 resting to 1.
  final double rise;

  /// The panel's width and top corners, which it becomes.
  final double panelWidth;
  final double panelRadius;

  const ClosestGlassHandle({
    super.key,
    required this.rise,
    required this.panelWidth,
    required this.panelRadius,
  });

  /// Over this part of the change the glass turns into the panel's colour.
  static const _filling = Interval(0.1, 0.55);

  @override
  Widget build(BuildContext context) {
    final progress = ClosestLiquidShape.progress(rise);
    final shape = ClosestLiquidShape.handle(progress, panelWidth, panelRadius);
    final filled = _filling.transform(progress);
    final colors = context.colors;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: shape.outerRect,
            child: Opacity(
              opacity: 1 - filled,
              child: filled < 1
                  ? GlassSurface(
                      borderRadius: BorderRadius.only(
                        topLeft: shape.tlRadius,
                        topRight: shape.trRadius,
                        bottomLeft: shape.blRadius,
                        bottomRight: shape.brRadius,
                      ),
                      child: const SizedBox.expand(),
                    )
                  : const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _HandleFillPainter(
                shape: shape,
                fill: colors.surface.withValues(alpha: filled),
                grip: Color.lerp(colors.textMuted, colors.textHint, progress)!,
                gripWidth: 36 + 4 * progress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The panel's colour filling the handle, and its grip.
class _HandleFillPainter extends CustomPainter {
  final RRect shape;
  final Color fill;
  final Color grip;
  final double gripWidth;

  const _HandleFillPainter({
    required this.shape,
    required this.fill,
    required this.grip,
    required this.gripWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fill.a > 0) canvas.drawRRect(shape, Paint()..color = fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: shape.center, width: gripWidth, height: 4),
        const Radius.circular(2),
      ),
      Paint()..color = grip,
    );
  }

  @override
  bool shouldRepaint(_HandleFillPainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.grip != grip ||
      old.gripWidth != gripWidth;
}
