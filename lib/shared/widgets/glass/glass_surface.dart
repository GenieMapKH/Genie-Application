import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/shared/widgets/glass/glass_style.dart';

/// A pane of glass floating over the map or a page, in the manner of iOS 26
/// and HyperOS: what is behind it is blurred and tinted, and a thin rim
/// catching the light separates it from what is behind. Only on phones whose
/// interface is glass: see `GlassScope`.
///
/// Built to stay cheap over the map: one filter ([BackdropFilter.grouped],
/// so every pane under one [BackdropGroup] shares a single read of the
/// screen; without a group, each pane reads it on its own), and the tint,
/// highlight and rim painted directly rather than through extra layers.
/// Nothing here animates, so the glass costs nothing while still.
///
/// On iOS the filter is a plain blur: iOS can apply nothing else over the
/// map. Elsewhere the blur also makes the colours behind more vivid
/// ([GlassStyle.saturation]), as Apple's glass does.
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

  /// Light, as Apple's glass is: what is behind stays recognisable, only
  /// softened; small text behind it no longer reads.
  static const blurSigma = 12.0;

  static ImageFilter _filterFor(GlassStyle style) {
    final blur = ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
    if (defaultTargetPlatform == TargetPlatform.iOS || style.saturation == 1) {
      return blur;
    }
    return ImageFilter.compose(
      outer: ColorFilter.matrix(saturationMatrix(style.saturation)),
      inner: blur,
    );
  }

  /// A colour matrix making colours [s] times as saturated, keeping their
  /// brightness (Rec. 709 weights).
  @visibleForTesting
  static List<double> saturationMatrix(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return [
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0, //
      r * i, g * i, b * i + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

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
          filter: _filterFor(style),
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

    // Only a breath of tint: what is behind keeps its own colours.
    canvas.drawRRect(
      shape,
      Paint()..color = style.tint.withValues(alpha: style.tintAlpha),
    );

    // A faint light from above, gone by the middle.
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

    // The rim: bright at the corner the light strikes and glinting at the
    // opposite one, a fine line along the sides between.
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
            Colors.white.withValues(alpha: style.rimSideAlpha),
            Colors.white.withValues(alpha: style.rimSideAlpha),
            Colors.white.withValues(alpha: style.rimEndAlpha),
          ],
          stops: const [0, 0.4, 0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GlassPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.style != style;
}
