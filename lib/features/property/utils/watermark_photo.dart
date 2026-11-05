import 'dart:typed_data';
import 'dart:ui' as ui;

/// The app's mark on listing photos: the same on screen and in saved files.
abstract final class PhotoWatermarkSpec {
  /// The light logo, readable over the dark and busy parts of a photo.
  static const asset = 'assets/images/brand/logo_on_dark.png';

  /// How wide the logo is, as a share of the photo's width.
  static const widthFactor = 0.3;

  /// Faint enough to look through, strong enough to survive a crop.
  static const opacity = 0.35;
}

/// Draws [logo] faintly in the middle of [photo] and returns the result as
/// PNG bytes.
///
/// The logo is [widthFactor] of the photo's width (capped so it also fits a
/// very wide photo's height) and drawn at [opacity]. Null when either
/// picture cannot be decoded.
Future<Uint8List?> watermarkPhoto({
  required Uint8List photo,
  required Uint8List logo,
  required double widthFactor,
  required double opacity,
}) async {
  final photoImage = await _decode(photo);
  final logoImage = await _decode(logo);
  if (photoImage == null || logoImage == null) return null;

  try {
    final width = photoImage.width.toDouble();
    final height = photoImage.height.toDouble();
    final logoAspect = logoImage.height / logoImage.width;
    var logoWidth = width * widthFactor;
    // A panorama: keep the logo inside the photo's height.
    if (logoWidth * logoAspect > height * 0.8) {
      logoWidth = height * 0.8 / logoAspect;
    }
    final logoHeight = logoWidth * logoAspect;
    final logoRect = ui.Rect.fromLTWH(
      (width - logoWidth) / 2,
      (height - logoHeight) / 2,
      logoWidth,
      logoHeight,
    );

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(photoImage, ui.Offset.zero, ui.Paint());
    canvas.drawImageRect(
      logoImage,
      ui.Rect.fromLTWH(
        0,
        0,
        logoImage.width.toDouble(),
        logoImage.height.toDouble(),
      ),
      logoRect,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.high
        ..color = ui.Color.fromRGBO(0, 0, 0, opacity),
    );
    final picture = recorder.endRecording();
    final marked = await picture.toImage(photoImage.width, photoImage.height);
    picture.dispose();
    try {
      final bytes = await marked.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } finally {
      marked.dispose();
    }
  } finally {
    photoImage.dispose();
    logoImage.dispose();
  }
}

Future<ui.Image?> _decode(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } on Exception {
    return null;
  }
}
