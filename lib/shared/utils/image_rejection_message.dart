import 'package:tilomnov/core/media/image_upload_policy.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// What to tell the user when a picture could not be prepared for upload.
String imageRejectionMessage(AppLocalizations l10n, ImageRejection reason) {
  return switch (reason) {
    ImageRejection.sourceTooLarge => l10n.mediaSourceTooLarge(
      ImageUploadPolicy.maxSourceBytes ~/ (1024 * 1024),
    ),
    ImageRejection.stillTooLarge => l10n.mediaStillTooLarge,
    ImageRejection.unreadable => l10n.mediaUnreadable,
  };
}
