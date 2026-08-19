import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> getSvgMarker(String assetName) async {
  try {
    final String svgString = await rootBundle.loadString(assetName);
    
    final PictureInfo pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
    
    // Use exact SVG size so the anchor offset remains accurate on the map
    final double targetWidth = pictureInfo.size.width;
    final double targetHeight = pictureInfo.size.height;
    
    final ui.Image image = await pictureInfo.picture.toImage(
        targetWidth.toInt(), targetHeight.toInt());
        
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    
    final Uint8List uint8List = byteData.buffer.asUint8List();
    
    // Using BitmapDescriptor.bytes with width and height ensures Flutter Web correctly applies the anchor point
    return BitmapDescriptor.bytes(
      uint8List,
      width: targetWidth,
      height: targetHeight,
    );
  } catch (e) {
    debugPrint('Error loading SVG marker: $e');
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }
}
