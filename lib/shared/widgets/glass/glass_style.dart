import 'package:flutter/material.dart';

/// How a pane of glass is tinted and lit, one look for each theme.
///
/// Clear, as Apple's Liquid Glass is, not frosted: a light blur, colours
/// behind made more vivid rather than washed out, only a breath of tint,
/// and the light held in a crisp rim around the edge. Light glass is tinted
/// white; dark glass a near-black navy (a mid navy turns the map's greens
/// and greys into a murky slate).
@immutable
class GlassStyle {
  /// The colour laid over what is behind, at [tintAlpha].
  final Color tint;
  final double tintAlpha;

  /// How much more vivid the colours behind turn: 1 leaves them, 1.8 is
  /// Apple's vibrancy. Only where the platform allows more than a blur.
  final double saturation;

  /// The faint white that falls from the top edge to the middle.
  final double highlightAlpha;

  /// The white of the rim at the top-left corner, where the light strikes,
  /// and at the bottom-right one, where it glints through the glass. The
  /// sides between keep [rimSideAlpha], so the edge never disappears.
  final double rimStartAlpha;
  final double rimEndAlpha;
  final double rimSideAlpha;

  /// The two shadows under the pane (a wide soft one and a close one): light
  /// enough that another pane blurring them shows no smudge.
  final double softShadowAlpha;
  final double closeShadowAlpha;

  const GlassStyle({
    required this.tint,
    required this.tintAlpha,
    required this.saturation,
    required this.highlightAlpha,
    required this.rimStartAlpha,
    required this.rimEndAlpha,
    required this.rimSideAlpha,
    required this.softShadowAlpha,
    required this.closeShadowAlpha,
  });

  /// [surface] is the theme's surface colour, which the glass is tinted with.
  factory GlassStyle.of(Brightness brightness, Color surface) {
    if (brightness == Brightness.dark) {
      return GlassStyle(
        tint: Color.lerp(surface, Colors.black, 0.35)!,
        tintAlpha: 0.78,
        saturation: 1.0,
        highlightAlpha: 0.07,
        rimStartAlpha: 0.22,
        rimEndAlpha: 0.03,
        rimSideAlpha: 0.12,
        softShadowAlpha: 0.22,
        closeShadowAlpha: 0.14,
      );
    }
    return GlassStyle(
      tint: surface,
      tintAlpha: 0.70,
      saturation: 1.0,
      highlightAlpha: 0.28,
      rimStartAlpha: 0.75,
      rimEndAlpha: 0.10,
      rimSideAlpha: 0.42,
      softShadowAlpha: 0.10,
      closeShadowAlpha: 0.06,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlassStyle &&
      other.tint == tint &&
      other.tintAlpha == tintAlpha &&
      other.saturation == saturation &&
      other.highlightAlpha == highlightAlpha &&
      other.rimStartAlpha == rimStartAlpha &&
      other.rimEndAlpha == rimEndAlpha &&
      other.rimSideAlpha == rimSideAlpha;

  @override
  int get hashCode => Object.hash(
    tint,
    tintAlpha,
    saturation,
    highlightAlpha,
    rimStartAlpha,
    rimEndAlpha,
    rimSideAlpha,
  );
}
