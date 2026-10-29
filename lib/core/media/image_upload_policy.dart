import 'package:tilomnov/core/errors/app_exceptions.dart';

/// How large a picture may be before it is uploaded, and how small it is made.
///
/// A phone photo is 3 to 12 MB; a profile picture needs a few dozen KB. Every
/// picture is re-encoded as a JPEG on the device before it leaves it, so the
/// server and its storage only ever receive small files. The storage buckets
/// enforce their own, larger limit as the last line of defence (see
/// `tilomnov-backend/user/src/supabase`): [maxBytes] here is always below it.
class ImageUploadPolicy {
  /// The largest original the app will even try to read: bigger than this is
  /// refused before anything is decoded. A phone photo is never close.
  static const maxSourceBytes = 500 * 1024 * 1024;

  /// The picture's shorter side is reduced to this many pixels (a picture
  /// that is already smaller is left alone). The longer side follows.
  final int shortSide;

  /// The size compression aims for.
  final int targetBytes;

  /// What is accepted when the target cannot be met. Larger is refused.
  final int maxBytes;

  const ImageUploadPolicy({
    required this.shortSide,
    required this.targetBytes,
    required this.maxBytes,
  });

  /// Shown small and round: 480 px is sharp at any size the app draws it.
  static const avatar = ImageUploadPolicy(
    shortSide: 480,
    targetBytes: 120 * 1024,
    maxBytes: 1024 * 1024,
  );

  /// A picture sent in a chat: readable full screen on a phone.
  static const chatPhoto = ImageUploadPolicy(
    shortSide: 1080,
    targetBytes: 400 * 1024,
    maxBytes: 3 * 1024 * 1024,
  );

  /// A listing photo, shown large on the property page.
  static const propertyPhoto = ImageUploadPolicy(
    shortSide: 1280,
    targetBytes: 600 * 1024,
    maxBytes: 4 * 1024 * 1024,
  );
}

/// Why a picture was not accepted for upload.
enum ImageRejection {
  /// The original is larger than [ImageUploadPolicy.maxSourceBytes].
  sourceTooLarge,

  /// Still above [ImageUploadPolicy.maxBytes] after the strongest compression.
  stillTooLarge,

  /// The file is not a picture the device could decode.
  unreadable,
}

class ImageRejectedException extends AppException {
  final ImageRejection reason;

  const ImageRejectedException(this.reason) : super('Image rejected');
}
