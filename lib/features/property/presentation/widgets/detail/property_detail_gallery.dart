import 'package:genie/shared/widgets/app_network_image.dart';
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
                errorWidget: const PropertyImagePlaceholder(),
              );

        return SizedBox(
          height: photoHeight,
          width: double.infinity,
          child: child,
        );
      },
    );
  }
}
