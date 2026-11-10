import 'package:flutter/material.dart';

import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';
import 'package:tilomnov/shared/widgets/media/app_network_image.dart';

/// One listing photo in the detail sheet, cropped to fill its box.
///
/// Shows its thumbnail (usually already on the device from the card that was
/// tapped) until the full photo arrives, so a slow connection shows a picture
/// at once instead of an empty box.
class PropertyDetailPhoto extends StatelessWidget {
  final String url;

  /// The small copy of [url]; null or equal to [url] when it has none.
  final String? thumbnailUrl;

  const PropertyDetailPhoto({super.key, required this.url, this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/') || url.startsWith('assets\\')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const PropertyImagePlaceholder(),
      );
    }
    final thumbnail = _thumbnail();
    return AppNetworkImage(
      url: url,
      placeholder: thumbnail,
      errorWidget: thumbnail ?? const PropertyImagePlaceholder(),
    );
  }

  Widget? _thumbnail() {
    final thumbnail = thumbnailUrl;
    if (thumbnail == null || thumbnail == url) return null;
    return AppNetworkImage(
      url: thumbnail,
      errorWidget: const PropertyImagePlaceholder(),
    );
  }
}
