import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/glass/glass_surface.dart';

/// A round floating map button drawn from an SVG, repainted in the current
/// theme. The artwork bakes in a white disc, a light-grey ring and a grey
/// glyph, which would stay white on the dark map.
///
/// Where the navigation is glass, the disc is glass too: the artwork's disc
/// and ring are left out and a [GlassSurface] takes their place.
class MapButtonIcon extends ConsumerWidget {
  final String asset;
  final double width;
  final double height;

  const MapButtonIcon({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
  });

  static const _artDiscColor = Color(0xFFFFFFFF);
  static const _artRing = Color(0xFFE5E7EB);
  static const _artGlyph = Color(0xFF6B7280);

  /// Where every artwork draws its disc, in its 76-wide canvas.
  static const _artWidth = 76.0;
  static const _artDisc = Rect.fromLTWH(16, 12, 44, 44);

  /// The share of a 76-wide artwork that is its disc, which sits centred: an
  /// [Align] of this width crops the button to the disc and nothing more.
  static const discWidthFactor = 44 / _artWidth;

  static const _transparent = Color(0x00000000);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final glass = watchGlassNavigation(ref, context);
    final picture = SvgPicture.asset(
      asset,
      width: width,
      height: height,
      colorMapper: _ThemeColorMapper(
        glass
            ? {
                _artDiscColor: _transparent,
                _artRing: _transparent,
                _artGlyph: colors.textPrimary,
              }
            : {
                _artDiscColor: colors.surface,
                _artRing: colors.border,
                _artGlyph: colors.textMuted,
              },
      ),
    );
    if (!glass) return picture;

    final scale = width / _artWidth;
    final disc = Rect.fromLTWH(
      _artDisc.left * scale,
      _artDisc.top * scale,
      _artDisc.width * scale,
      _artDisc.height * scale,
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: disc,
            child: GlassSurface(
              borderRadius: BorderRadius.circular(disc.width / 2),
              child: const SizedBox.expand(),
            ),
          ),
          picture,
        ],
      ),
    );
  }
}

class _ThemeColorMapper extends ColorMapper {
  final Map<Color, Color> _replacements;

  const _ThemeColorMapper(this._replacements);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => _replacements[color] ?? color;

  // Rebuilt per theme, so a theme change must repaint the picture.
  @override
  bool operator ==(Object other) =>
      other is _ThemeColorMapper && _sameReplacements(other._replacements);

  bool _sameReplacements(Map<Color, Color> other) {
    if (other.length != _replacements.length) return false;
    for (final entry in _replacements.entries) {
      if (other[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_replacements.values);
}
