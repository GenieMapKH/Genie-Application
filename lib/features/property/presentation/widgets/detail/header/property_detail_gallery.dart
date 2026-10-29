import 'package:tilomnov/shared/widgets/media/app_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';

/// The detail sheet's photo strip: full-width images stacked vertically so
/// scrolling walks through the listing's photos.
///
/// Each photo shows its thumbnail (usually already on the device from the
/// card that was tapped) until the full photo arrives, so a slow connection
/// shows a picture at once instead of an empty box.
class PropertyDetailGallery extends StatelessWidget {
  final List<String> imageUrls;

  /// Same order and length as [imageUrls] (see `PropertyModel.cardImageUrls`).
  final List<String> thumbnailUrls;

  const PropertyDetailGallery({
    super.key,
    required this.imageUrls,
    required this.thumbnailUrls,
  });

  /// Height of each photo in the strip.
  static const double photoHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: photoHeight,
          width: double.infinity,
          child: PropertyImagePlaceholder(),
        ),
      );
    }

    final images = imageUrls;

    return SliverList.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        final url = images[index];
        final child = url.startsWith('assets/') || url.startsWith('assets\\')
            ? Image.asset(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const PropertyImagePlaceholder(),
              )
            : AppNetworkImage(
                url: url,
                placeholder: _thumbnailOf(index),
                errorWidget:
                    _thumbnailOf(index) ?? const PropertyImagePlaceholder(),
              );

        return SizedBox(
          height: photoHeight,
          width: double.infinity,
          child: child,
        );
      },
    );
  }

  /// The small copy of photo [index], or null when it has none of its own.
  Widget? _thumbnailOf(int index) {
    if (index >= thumbnailUrls.length) return null;
    final thumbnail = thumbnailUrls[index];
    if (thumbnail == imageUrls[index]) return null;
    return AppNetworkImage(
      url: thumbnail,
      errorWidget: const PropertyImagePlaceholder(),
    );
  }
}
