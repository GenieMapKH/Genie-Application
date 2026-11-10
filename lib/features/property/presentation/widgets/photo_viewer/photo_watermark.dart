import 'package:flutter/material.dart';

import 'package:tilomnov/features/property/utils/watermark_photo.dart';

/// The faint logo laid over a listing photo wherever a full photo is shown,
/// so a screenshot carries it. Saved photos get the same mark burned in (see
/// `watermarkPhoto`).
class PhotoWatermark extends StatelessWidget {
  const PhotoWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: PhotoWatermarkSpec.widthFactor,
          child: Opacity(
            opacity: PhotoWatermarkSpec.opacity,
            child: Image.asset(PhotoWatermarkSpec.asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
