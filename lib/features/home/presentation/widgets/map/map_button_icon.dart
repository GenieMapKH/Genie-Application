import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:genie/core/theme/app_colors.dart';

/// A round floating map button drawn from an SVG, repainted in the current
/// theme. The artwork bakes in a white disc, a light-grey ring and a grey
/// glyph, which would stay white on the dark map.
class MapButtonIcon extends StatelessWidget {
  final String asset;
  final double width;
  final double height;

  const MapButtonIcon({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
  });

  static const _artDisc = Color(0xFFFFFFFF);
  static const _artRing = Color(0xFFE5E7EB);
  static const _artGlyph = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      colorMapper: _ThemeColorMapper({
        _artDisc: colors.surface,
        _artRing: colors.border,
        _artGlyph: colors.textMuted,
      }),
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
