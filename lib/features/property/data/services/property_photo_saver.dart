import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';

import 'package:tilomnov/core/media/app_image_cache.dart';
import 'package:tilomnov/features/property/utils/watermark_photo.dart';

/// How saving a listing photo ended, when it did not throw.
enum PhotoSaveResult { saved, accessDenied }

/// Saves a listing photo to the phone's gallery, always with the app's logo
/// burned in, as it is shown on screen.
class PropertyPhotoSaver {
  const PropertyPhotoSaver();

  /// Throws when the photo cannot be read, marked or written.
  Future<PhotoSaveResult> save(String url, {required String name}) async {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      return PhotoSaveResult.accessDenied;
    }
    final photo = await _readPhoto(url);
    final logo = await rootBundle.load(PhotoWatermarkSpec.asset);
    final marked = await watermarkPhoto(
      photo: photo,
      logo: logo.buffer.asUint8List(),
      widthFactor: PhotoWatermarkSpec.widthFactor,
      opacity: PhotoWatermarkSpec.opacity,
    );
    if (marked == null) throw StateError('The photo could not be decoded');
    // A full photo as PNG is several megabytes; as JPEG, a fraction.
    final jpeg = await FlutterImageCompress.compressWithList(
      marked,
      quality: 92,
      format: CompressFormat.jpeg,
    );
    await Gal.putImageBytes(jpeg, name: name);
    return PhotoSaveResult.saved;
  }

  /// Usually already on the device, from being looked at.
  Future<Uint8List> _readPhoto(String url) async {
    if (url.startsWith('assets/')) {
      final data = await rootBundle.load(url);
      return data.buffer.asUint8List();
    }
    final file = await AppImageCache.files.getSingleFile(url);
    return file.readAsBytes();
  }
}
