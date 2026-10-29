import 'package:flutter/material.dart';

/// How a pane of glass is tinted and lit, one look for each theme.
///
/// Light glass is frosted white: bright, with a strong catch of light on its
/// edge. Dark glass is not the light one with the colours swapped: tinted over
/// the theme's navy, it has to be deep enough to stay navy over a pale map
/// (a thin navy turns the map's greens and greys into a murky slate), and
/// its light is dimmer, as it is in a dark interface.
@immutable
class GlassStyle {
  /// The colour laid over the blurred map, at [tintAlpha].
  final Color tint;
  final double tintAlpha;

  /// The white that falls from the top edge down to the middle.
  final double highlightAlpha;

  /// The white of the rim where the light strikes, and where it fades out.
  final double rimStartAlpha;
  final double rimEndAlpha;

  /// The two shadows under the pane (a wide soft one and a close one).
  final double softShadowAlpha;
  final double closeShadowAlpha;

  const GlassStyle({
    required this.tint,
    required this.tintAlpha,
    required this.highlightAlpha,
    required this.rimStartAlpha,
    required this.rimEndAlpha,
    required this.softShadowAlpha,
    required this.closeShadowAlpha,
  });

  /// [surface] is the theme's surface colour, which the glass is tinted with.
  factory GlassStyle.of(Brightness brightness, Color surface) {
    if (brightness == Brightness.dark) {
      return GlassStyle(
        tint: Color.lerp(surface, Colors.black, 0.35)!,
        tintAlpha: 0.78,
        highlightAlpha: 0.07,
        rimStartAlpha: 0.22,
        rimEndAlpha: 0.03,
        softShadowAlpha: 0.22,
        closeShadowAlpha: 0.14,
      );
    }
    return GlassStyle(
      tint: surface,
      tintAlpha: 0.70,
      highlightAlpha: 0.28,
      rimStartAlpha: 0.75,
      rimEndAlpha: 0.10,
      softShadowAlpha: 0.10,
      closeShadowAlpha: 0.06,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlassStyle &&
      other.tint == tint &&
      other.tintAlpha == tintAlpha &&
      other.highlightAlpha == highlightAlpha &&
      other.rimStartAlpha == rimStartAlpha &&
      other.rimEndAlpha == rimEndAlpha;

  @override
  int get hashCode => Object.hash(
    tint,
    tintAlpha,
    highlightAlpha,
    rimStartAlpha,
    rimEndAlpha,
  );
}
