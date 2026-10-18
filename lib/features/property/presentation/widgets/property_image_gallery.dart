import 'package:genie/shared/widgets/media/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:genie/core/theme/app_colors.dart';

/// Swipeable image gallery with a dot indicator, shared by the map card and the
/// similar-property tiles.
class PropertyImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final BorderRadius? borderRadius;
  final bool showIndicator;

  /// Max dots to render; galleries with more images cap the indicator so it
  /// doesn't overflow a narrow card.
  final int maxIndicatorDots;
  final ScrollPhysics? physics;

  const PropertyImageGallery({
    super.key,
    required this.imageUrls,
    this.borderRadius,
    this.showIndicator = true,
    this.maxIndicatorDots = 5,
    this.physics,
  });

  static List<String> fallbackImages(String? id, String? type) {
    return const [];
  }

  @override
  State<PropertyImageGallery> createState() => _PropertyImageGalleryState();
}

class _PropertyImageGalleryState extends State<PropertyImageGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      final placeholder = const PropertyImagePlaceholder();
      if (widget.borderRadius == null) return placeholder;
      return ClipRRect(borderRadius: widget.borderRadius!, child: placeholder);
    }

    final images = widget.imageUrls;

    if (images.length == 1) {
      final single = _buildImageItem(images.first);
      if (widget.borderRadius == null) return single;
      return ClipRRect(borderRadius: widget.borderRadius!, child: single);
    }

    final gallery = Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          physics: widget.physics,
          itemCount: images.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) => _buildImageItem(images[index]),
        ),
        if (widget.showIndicator && images.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: _Indicator(
              count: images.length,
              activeIndex: _index,
              maxDots: widget.maxIndicatorDots,
            ),
          ),
      ],
    );

    if (widget.borderRadius == null) return gallery;
    return ClipRRect(borderRadius: widget.borderRadius!, child: gallery);
  }

  Widget _buildImageItem(String url) {
    if (url.startsWith('assets/') || url.startsWith('assets\\')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const PropertyImagePlaceholder(),
      );
    }
    return AppNetworkImage(
      url: url,
      errorWidget: const PropertyImagePlaceholder(),
    );
  }
}

/// Windowed dot indicator: with more images than [maxDots] the dots slide so
/// the active one stays inside the window.
class _Indicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final int maxDots;

  const _Indicator({
    required this.count,
    required this.activeIndex,
    required this.maxDots,
  });

  @override
  Widget build(BuildContext context) {
    final visible = count < maxDots ? count : maxDots;
    int start = 0;
    if (count > maxDots) {
      start = (activeIndex - maxDots ~/ 2).clamp(0, count - maxDots);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(visible, (i) {
        final isActive = start + i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Neutral fill shown when a listing has no photos or one fails to load.
class PropertyImagePlaceholder extends StatelessWidget {
  const PropertyImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.divider,
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 44,
          color: context.colors.iconSubtle,
        ),
      ),
    );
  }
}
