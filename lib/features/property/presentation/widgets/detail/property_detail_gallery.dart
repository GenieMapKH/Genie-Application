import 'package:flutter/material.dart';

import 'package:genie/features/property/presentation/widgets/property_image_gallery.dart';

/// The detail sheet's photo strip: full-width images stacked vertically so
/// scrolling walks through the listing's photos.
class PropertyDetailGallery extends StatelessWidget {
  final List<String> imageUrls;

  const PropertyDetailGallery({super.key, required this.imageUrls});

  /// Height of each photo in the strip.
  static const double photoHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: photoHeight,
          child: PropertyImagePlaceholder(),
        ),
      );
    }

    return SliverList.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index) => SizedBox(
        height: photoHeight,
        width: double.infinity,
        child: Image.network(
          imageUrls[index],
          fit: BoxFit.cover,
          cacheWidth: 1200,
          errorBuilder: (_, _, _) => const PropertyImagePlaceholder(),
        ),
      ),
    );
  }
}
