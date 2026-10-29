import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tilomnov/core/media/app_image_cache.dart';
import 'package:tilomnov/core/theme/app_colors.dart';

/// A picture from a URL, kept on disk and in memory by [AppImageCache].
///
/// Decoded at the size it is drawn at, not at full resolution, so more
/// pictures stay in memory. A picture seen before appears at once: there is
/// no fade, and the placeholder is a plain box rather than a spinner, so a
/// picture read back from disk does not look like it is loading again.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Shown until the picture is ready. Defaults to a plain box.
  final Widget? placeholder;

  /// Shown when the picture cannot be loaded. Defaults to a broken-image icon.
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  /// The same caching for places that take an [ImageProvider] (a
  /// [CircleAvatar]), drawn in a square of [size] logical pixels.
  static ImageProvider provider(
    BuildContext context,
    String url, {
    required double size,
  }) {
    final image = CachedNetworkImageProvider(
      url,
      cacheManager: AppImageCache.files,
    );
    final decodeWidth = AppImageCache.decodeWidth(
      size,
      size,
      MediaQuery.devicePixelRatioOf(context),
    );
    return ResizeImage.resizeIfNeeded(decodeWidth, null, image);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeWidth = AppImageCache.decodeWidth(
          width ?? constraints.maxWidth,
          height ?? constraints.maxHeight,
          MediaQuery.devicePixelRatioOf(context),
        );

        return CachedNetworkImage(
          imageUrl: url,
          cacheManager: AppImageCache.files,
          width: width,
          height: height,
          fit: fit,
          memCacheWidth: decodeWidth,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (context, _) =>
              placeholder ?? ColoredBox(color: context.colors.divider),
          errorWidget: (context, _, _) =>
              errorWidget ?? _BrokenImage(width: width, height: height),
        );
      },
    );
  }
}

class _BrokenImage extends StatelessWidget {
  final double? width;
  final double? height;

  const _BrokenImage({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: context.colors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: context.colors.textHint),
    );
  }
}
