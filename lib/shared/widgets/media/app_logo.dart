import 'package:flutter/material.dart';

/// The brand logo in the version drawn for the current theme: the navy
/// wordmark on light backgrounds, the off-white stacked one on dark.
class AppLogo extends StatelessWidget {
  static const String lightAssetPath = 'assets/images/brand/logo_on_light.png';
  static const String darkAssetPath = 'assets/images/brand/logo_on_dark.png';

  /// The box the logo is fitted into; the two versions have different
  /// shapes, so each keeps its own aspect ratio inside it.
  final double width;
  final double height;

  const AppLogo({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? darkAssetPath : lightAssetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
