import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A one-colour SVG icon drawn in [color].
///
/// Use it instead of `SvgPicture.asset(colorFilter: ...)`: a colour filter
/// makes every frame draw the icon into a layer of its own and blend it in,
/// which the map's controls and the bottom bar paid on each frame while the
/// map moved. Here the colour is put into the icon once, when it is read,
/// and it is drawn like any other picture.
class TintedSvg extends StatelessWidget {
  final String assetName;
  final Color color;
  final double? width;
  final double? height;

  const TintedSvg(
    this.assetName, {
    super.key,
    required this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: width,
      height: height,
      colorMapper: TintedSvg.mapperFor(color),
      // Icons drawn in `currentColor` take it from the theme instead.
      theme: SvgTheme(currentColor: color),
    );
  }

  /// The colour mapper that puts [color] into an icon; for tests.
  @visibleForTesting
  static ColorMapper mapperFor(Color color) => _Tint(color);
}

/// Paints every colour of the icon in [tint], keeping each one's own
/// transparency: what `BlendMode.srcIn` did, without the layer.
class _Tint extends ColorMapper {
  final Color tint;

  const _Tint(this.tint);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => tint.withValues(alpha: tint.a * color.a);

  // The parsed icon is cached by its colour mapper: equal tints share it.
  @override
  bool operator ==(Object other) => other is _Tint && other.tint == tint;

  @override
  int get hashCode => tint.hashCode;
}
