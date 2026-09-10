import 'package:flutter/material.dart';

/// Swipeable image gallery with a dot indicator, shared by the map card and the
/// similar-property tiles.
class PropertyImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final BorderRadius? borderRadius;
  final bool showIndicator;

  /// Max dots to render; galleries with more images cap the indicator so it
  /// doesn't overflow a narrow card.
  final int maxIndicatorDots;

  const PropertyImageGallery({
    super.key,
    required this.imageUrls,
    this.borderRadius,
    this.showIndicator = true,
    this.maxIndicatorDots = 5,
  });

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
    final images = widget.imageUrls;
    final gallery = images.isEmpty
        ? const PropertyImagePlaceholder()
        : Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  errorBuilder: (_, _, _) => const PropertyImagePlaceholder(),
                ),
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
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
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
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 44,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
