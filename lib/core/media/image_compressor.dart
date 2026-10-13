import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart'
    show CompressFormat, FlutterImageCompress;
import 'package:image_picker/image_picker.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/media/image_upload_policy.dart';

/// A picture ready to upload: always a JPEG, as small as the policy asks.
class PreparedImage {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  const PreparedImage({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });

  /// The picture as a file that can be read again, for code that works with
  /// [XFile]s. The path is only the name: without it an [XFile] made from
  /// bytes would report an empty name.
  XFile toXFile() =>
      XFile.fromData(bytes, name: name, path: name, mimeType: mimeType);
}

/// Re-encodes one picture as a JPEG whose shorter side is [shortSide] pixels
/// at most. Null when the file cannot be decoded.
typedef ImageEncoder =
    Future<Uint8List?> Function(
      String path, {
      required int shortSide,
      required int quality,
    });

/// Turns whatever the user picked (a 12 MB photo, a PNG screenshot, a HEIC
/// from an iPhone) into a small JPEG before it is uploaded.
///
/// Re-encoding also drops the picture's metadata, location included, which
/// nobody receiving a profile or chat picture needs.
class ImageCompressor {
  /// Tried from best to worst until the picture is small enough.
  static const _qualities = [85, 75, 65, 50, 40];

  /// If even the lowest quality is too big, the picture is also made this
  /// much smaller and the qualities are tried again.
  static const _shrinkFactor = 0.7;

  static const mimeType = 'image/jpeg';

  /// Encodes with the device's own image codecs (no Dart-side decoding, so a
  /// large photo does not fill the app's memory).
  static final ImageCompressor native = ImageCompressor(_encodeNatively);

  final ImageEncoder _encode;

  ImageCompressor(this._encode);

  /// Throws [ImageRejectedException] when [file] is larger than
  /// [ImageUploadPolicy.maxSourceBytes], cannot be decoded, or cannot be made
  /// smaller than [ImageUploadPolicy.maxBytes].
  Future<PreparedImage> compress(XFile file, ImageUploadPolicy policy) async {
    final sourceBytes = await file.length();
    if (sourceBytes > ImageUploadPolicy.maxSourceBytes) {
      throw const ImageRejectedException(ImageRejection.sourceTooLarge);
    }

    Uint8List? smallest;
    var smallestAt = '';
    var shortSide = policy.shortSide;
    for (var pass = 0; pass < 2; pass++) {
      for (final quality in _qualities) {
        final bytes = await _encode(
          file.path,
          shortSide: shortSide,
          quality: quality,
        );
        if (bytes == null || bytes.isEmpty) {
          throw const ImageRejectedException(ImageRejection.unreadable);
        }

        final attempt = 'q$quality, short side $shortSide px';
        if (smallest == null || bytes.length < smallest.length) {
          smallest = bytes;
          smallestAt = attempt;
        }
        if (bytes.length <= policy.targetBytes) {
          AppLogger.debug(
            'Image ${file.name}: $sourceBytes -> ${bytes.length} bytes ($attempt)',
          );
          return _prepared(file, bytes);
        }
      }
      shortSide = (shortSide * _shrinkFactor).round();
    }

    // The target could not be met; the smallest result may still be fine.
    if (smallest!.length > policy.maxBytes) {
      throw const ImageRejectedException(ImageRejection.stillTooLarge);
    }
    AppLogger.debug(
      'Image ${file.name}: $sourceBytes -> ${smallest.length} bytes '
      '($smallestAt, above the ${policy.targetBytes} byte target)',
    );
    return _prepared(file, smallest);
  }

  PreparedImage _prepared(XFile file, Uint8List bytes) {
    // Some platforms report the whole path as the name.
    final fileName = file.name.split(RegExp(r'[/\\]')).last;
    final dot = fileName.lastIndexOf('.');
    final base = dot < 0 ? fileName : fileName.substring(0, dot);
    return PreparedImage(
      bytes: bytes,
      name: '${base.isEmpty ? 'image' : base}.jpg',
      mimeType: mimeType,
    );
  }

  static Future<Uint8List?> _encodeNatively(
    String path, {
    required int shortSide,
    required int quality,
  }) {
    // The plugin scales the picture down until its shorter side reaches
    // the given size, and keeps the proportions.
    return FlutterImageCompress.compressWithFile(
      path,
      minWidth: shortSide,
      minHeight: shortSide,
      quality: quality,
      format: CompressFormat.jpeg,
    );
  }
}
