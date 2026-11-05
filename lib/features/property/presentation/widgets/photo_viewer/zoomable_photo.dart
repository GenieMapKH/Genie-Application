import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tilomnov/core/media/app_image_cache.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:tilomnov/shared/widgets/media/app_network_image.dart';

/// One photo of the full-screen viewer, whole on screen. Pinch to zoom up to
/// [_maxScale]; double-tap zooms in on the tapped spot, or back out.
///
/// Decoded at full size (not at screen size, as lists do) so it stays sharp
/// when zoomed. Its thumbnail shows until it arrives.
class ZoomablePhoto extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;

  /// Whether the photo is zoomed in, each time that changes.
  final ValueChanged<bool> onZoomChanged;

  const ZoomablePhoto({
    super.key,
    required this.url,
    required this.onZoomChanged,
    this.thumbnailUrl,
  });

  @override
  State<ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _zoomAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomTween;
  Offset _doubleTapAt = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformed);
    _zoomAnimation.addListener(() {
      final tween = _zoomTween;
      if (tween != null) _transform.value = tween.value;
    });
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onTransformed() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged(zoomed);
  }

  void _toggleZoom() {
    final Matrix4 target;
    if (_zoomed) {
      target = Matrix4.identity();
    } else {
      final at = _doubleTapAt;
      target = Matrix4.identity()
        ..translateByDouble(
          -at.dx * (_doubleTapScale - 1),
          -at.dy * (_doubleTapScale - 1),
          0,
          1,
        )
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    }
    _zoomTween = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeOutCubic),
    );
    _zoomAnimation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: _maxScale,
        child: SizedBox.expand(child: _photo()),
      ),
    );
  }

  Widget _photo() {
    final fallback = _thumbnail() ?? const PropertyImagePlaceholder();
    if (widget.url.startsWith('assets/')) {
      return Image.asset(widget.url, fit: BoxFit.contain);
    }
    return Image(
      image: CachedNetworkImageProvider(
        widget.url,
        cacheManager: AppImageCache.files,
      ),
      fit: BoxFit.contain,
      frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
          frame == null && !wasSynchronouslyLoaded ? fallback : child,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget? _thumbnail() {
    final thumbnail = widget.thumbnailUrl;
    if (thumbnail == null || thumbnail == widget.url) return null;
    return AppNetworkImage(url: thumbnail, fit: BoxFit.contain);
  }
}
