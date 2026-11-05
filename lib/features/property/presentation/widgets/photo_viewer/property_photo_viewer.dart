import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/photo_watermark.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/save_photo_button.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/zoomable_photo.dart';

/// A listing's photos full screen on black: swipe between them, pinch or
/// double-tap to zoom, and save one to the phone. The app's logo stays
/// faintly over the middle, so a screenshot carries it too.
///
/// Pops with the index of the photo last shown, so the cover behind can
/// turn to it.
class PropertyPhotoViewer extends StatefulWidget {
  final List<String> imageUrls;

  /// Same order and length as [imageUrls]; shown until a photo arrives.
  final List<String> thumbnailUrls;
  final int initialIndex;

  /// Names the saved files.
  final String propertyId;

  const PropertyPhotoViewer({
    super.key,
    required this.imageUrls,
    required this.thumbnailUrls,
    required this.initialIndex,
    required this.propertyId,
  });

  /// Fades in over the listing, above the tab bar.
  static Future<int?> open(
    BuildContext context, {
    required List<String> imageUrls,
    required List<String> thumbnailUrls,
    required int initialIndex,
    required String propertyId,
  }) {
    return Navigator.of(context, rootNavigator: true).push<int>(
      PageRouteBuilder<int>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, _, _) => PropertyPhotoViewer(
          imageUrls: imageUrls,
          thumbnailUrls: thumbnailUrls,
          initialIndex: initialIndex,
          propertyId: propertyId,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<PropertyPhotoViewer> createState() => _PropertyPhotoViewerState();
}

class _PropertyPhotoViewerState extends State<PropertyPhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  /// While a photo is zoomed in, a drag pans it instead of turning the page.
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop(_index);

  @override
  Widget build(BuildContext context) {
    final count = widget.imageUrls.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pages,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: count,
                onPageChanged: (index) => setState(() {
                  _index = index;
                  _zoomed = false;
                }),
                itemBuilder: (context, index) => ZoomablePhoto(
                  url: widget.imageUrls[index],
                  thumbnailUrl: index < widget.thumbnailUrls.length
                      ? widget.thumbnailUrls[index]
                      : null,
                  onZoomChanged: (zoomed) {
                    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                  },
                ),
              ),
              const PhotoWatermark(),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _close,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white,
                        ),
                        Expanded(
                          child: Text(
                            '${_index + 1} / $count',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SavePhotoButton(
                          url: widget.imageUrls[_index],
                          fileName:
                              'tilomnov-${widget.propertyId}-${_index + 1}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
