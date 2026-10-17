import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Where pictures loaded from a URL are kept, on disk and in memory.
///
/// Every uploaded picture (listing photos, avatars) is stored under a new
/// random name, so a URL never starts showing a different picture and a
/// downloaded file can be kept for long.
abstract final class AppImageCache {
  /// Files not shown for this long are removed from the device.
  static const _keepUnused = Duration(days: 30);

  /// Enough for a long browsing session of listings and avatars.
  static const _maxFiles = 1000;

  /// Decoded pictures kept ready to draw. Flutter's default (100 MB) holds
  /// too few listing photos, so covers had to be decoded again after a tab
  /// switch.
  static const _memoryBytes = 200 << 20;

  static final CacheManager files = CacheManager(
    Config(
      'genie_images',
      stalePeriod: _keepUnused,
      maxNrOfCacheObjects: _maxFiles,
    ),
  );

  /// Call once before the first frame.
  static void configureMemory() {
    PaintingBinding.instance.imageCache.maximumSizeBytes = _memoryBytes;
  }

  /// The width, in pixels, to decode a picture at for a box of [logicalWidth]
  /// x [logicalHeight]. Uses the longer side, so a wide photo filling a tall
  /// box (`BoxFit.cover`) stays sharp. Rounded up to steps so a box that
  /// changes size slightly (an animation) reuses the same decoded picture.
  static int? decodeWidth(
    double logicalWidth,
    double logicalHeight,
    double devicePixelRatio,
  ) {
    double usable(double v) => v.isFinite && v > 0 ? v : 0;
    final side = max(usable(logicalWidth), usable(logicalHeight));
    if (side == 0) return null;

    const step = 200;
    final pixels = (side * devicePixelRatio / step).ceil() * step;
    return min(pixels, 2000);
  }
}
