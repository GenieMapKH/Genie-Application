import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The brand logo in the version drawn for the current theme: the navy
/// one on light backgrounds, the off-white one on dark. Vector, so it stays
/// sharp at any size.
class AppLogo extends StatelessWidget {
  static const String lightAssetPath = 'assets/images/brand/logo_on_light.svg';
  static const String darkAssetPath = 'assets/images/brand/logo_on_dark.svg';

  /// The box the logo is fitted into, keeping its aspect ratio.
  final double width;
  final double height;

  const AppLogo({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      isDark ? darkAssetPath : lightAssetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
