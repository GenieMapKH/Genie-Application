import 'package:flutter/material.dart';

import 'package:tilomnov/features/property/presentation/widgets/detail/header/property_detail_photo.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/header/property_photo_counter.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/photo_watermark.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/property_photo_viewer.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';

/// A cover one photo high, the price and description under it. Swiping
/// sideways walks through the photos; tapping one opens it full screen.
///
/// The detail sheet uses it for a listing with at most one photo; one with
/// more gets `PropertyDetailPhotoLayout`, its photos stacked to scroll
/// through.
class PropertyDetailGallery extends StatefulWidget {
  final List<String> imageUrls;

  /// Same order and length as [imageUrls] (see `PropertyModel.cardImageUrls`).
  final List<String> thumbnailUrls;

  /// Names photos saved from the full-screen viewer.
  final String propertyId;

  const PropertyDetailGallery({
    super.key,
    required this.imageUrls,
    required this.thumbnailUrls,
    required this.propertyId,
  });

  /// Height of the cover.
  static const double photoHeight = 240.0;

  /// How much of the cover's bottom the sheet's body overlaps.
  static const double _coveredBottom = 20.0;

  @override
  State<PropertyDetailGallery> createState() => _PropertyDetailGalleryState();
}

class _PropertyDetailGalleryState extends State<PropertyDetailGallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _openViewer(int index) async {
    final shownLast = await PropertyPhotoViewer.open(
      context,
      imageUrls: widget.imageUrls,
      thumbnailUrls: widget.thumbnailUrls,
      initialIndex: index,
      propertyId: widget.propertyId,
    );
    // Back on the photo looked at last.
    if (shownLast != null && mounted && _pages.hasClients) {
      _pages.jumpToPage(shownLast);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: PropertyDetailGallery.photoHeight,
        width: double.infinity,
        child: images.isEmpty
            ? const PropertyImagePlaceholder()
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pages,
                    itemCount: images.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _openViewer(index),
                      child: _photo(index),
                    ),
                  ),
                  const PhotoWatermark(),
                  if (images.length > 1)
                    Positioned(
                      right: 12,
                      bottom: PropertyDetailGallery._coveredBottom + 10,
                      child: PropertyPhotoCounter(
                        index: _index,
                        count: images.length,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _photo(int index) => PropertyDetailPhoto(
    url: widget.imageUrls[index],
    thumbnailUrl: index < widget.thumbnailUrls.length
        ? widget.thumbnailUrls[index]
        : null,
  );
}
