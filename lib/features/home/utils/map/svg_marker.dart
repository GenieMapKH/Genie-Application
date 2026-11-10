import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'markers/marker_renderer.dart';

Future<BitmapDescriptor> getSvgMarker(String assetName) async {
  try {
    final String svgString = await rootBundle.loadString(assetName);

    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgStringLoader(svgString),
      null,
    );

    const width = 34.0;
    final scale = width / pictureInfo.size.width;
    try {
      // Preserve the aspect ratio and anchor, using the map's shared 3x renderer.
      return await renderMarker(
        width: width,
        height: pictureInfo.size.height * scale,
        draw: (canvas) => canvas
          ..scale(scale)
          ..drawPicture(pictureInfo.picture),
      );
    } finally {
      pictureInfo.picture.dispose();
    }
  } catch (e) {
    AppLogger.debug('Error loading SVG marker: $e');
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
}
