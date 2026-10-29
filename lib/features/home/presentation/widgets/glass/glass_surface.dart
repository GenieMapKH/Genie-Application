import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_style.dart';

/// A pane of glass floating over the map, in the manner of iOS 26 and
/// HyperOS: what is behind it is blurred and tinted, light catches its top
/// edge, and a thin rim separates it from the map.
///
/// Built to stay cheap over the map: one blur ([BackdropFilter.grouped], so
/// every pane under one [BackdropGroup] shares a single read of the screen),
/// a plain blur only (iOS cannot apply anything else over the map), and the
/// tint, highlight and rim painted directly rather than through extra
/// layers. Nothing here animates, so the glass costs nothing while still.
class GlassSurface extends StatelessWidget {
  /// A fully rounded capsule or circle: the shapes iOS draws glass in, and
  /// the clip iOS can apply to the blurred map.
  final BorderRadius borderRadius;
  final Widget child;

  /// Whether the pane casts a shadow on the map.
  final bool shadow;

  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
    this.shadow = true,
  });

  /// Strong enough to turn map labels into colour, light enough to keep the
  /// map's shapes readable through the glass.
  static const blurSigma = 12.0;

  @override
  Widget build(BuildContext context) {
    final style = GlassStyle.of(
      Theme.of(context).brightness,
      context.colors.surface,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: style.softShadowAlpha),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: style.closeShadowAlpha),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: GlassPainter(borderRadius: borderRadius, style: style),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The tint, top highlight and rim of [GlassSurface].
class GlassPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final GlassStyle style;

  const GlassPainter({required this.borderRadius, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = borderRadius.toRRect(rect);

    // Enough of the tint to keep small labels readable over a busy map.
    canvas.drawRRect(
      shape,
      Paint()..color = style.tint.withValues(alpha: style.tintAlpha),
    );

    // Light from above: brightest at the top edge, gone by the middle.
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Colors.white.withValues(alpha: style.highlightAlpha),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    // The rim: bright where the light strikes it, fading round the far side.
    const rim = 1.0;
    canvas.drawRRect(
      shape.deflate(rim / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: style.rimStartAlpha),
            Colors.white.withValues(alpha: style.rimEndAlpha),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GlassPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.style != style;
}
