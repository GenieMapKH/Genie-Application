import 'package:flutter/material.dart';

import 'package:tilomnov/features/property/presentation/widgets/detail/header/property_detail_photo.dart';
import 'package:tilomnov/features/property/presentation/widgets/photo_viewer/photo_watermark.dart';

/// A listing's photos stacked one under another, full width, scrolled up and
/// down. Tapping one hands back its index.
class PropertyPhotoColumn extends StatelessWidget {
  final List<String> imageUrls;

  /// Same order and length as [imageUrls] (see `PropertyModel.cardImageUrls`).
  final List<String> thumbnailUrls;
  final ScrollController controller;

  /// Height of each photo.
  final double photoHeight;

  /// Room under the last photo, so it can scroll clear of what covers the
  /// bottom of the column.
  final double bottomPadding;
  final ValueChanged<int> onTapPhoto;

  const PropertyPhotoColumn({
    super.key,
    required this.imageUrls,
    required this.thumbnailUrls,
    required this.controller,
    required this.photoHeight,
    required this.bottomPadding,
    required this.onTapPhoto,
  });

  /// Space between two photos.
  static const double gap = 4;

  /// How far [index]'s photo starts from the top of the column.
  double offsetOf(int index) => index * (photoHeight + gap);

  /// The photo at the top of the column when it is scrolled by [offset].
  int indexAt(double offset) =>
      ((offset + photoHeight / 2) / (photoHeight + gap)).floor().clamp(
        0,
        imageUrls.length - 1,
      );

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      itemCount: imageUrls.length,
      separatorBuilder: (_, _) => const SizedBox(height: gap),
      itemBuilder: (context, index) => SizedBox(
        height: photoHeight,
        child: GestureDetector(
          onTap: () => onTapPhoto(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PropertyDetailPhoto(
                url: imageUrls[index],
                thumbnailUrl: index < thumbnailUrls.length
                    ? thumbnailUrls[index]
                    : null,
              ),
              const PhotoWatermark(),
            ],
          ),
        ),
      ),
    );
  }
}
