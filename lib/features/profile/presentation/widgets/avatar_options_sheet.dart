import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/media/image_compressor.dart';
import 'package:tilomnov/core/media/image_upload_policy.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/avatar_controller.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'package:tilomnov/shared/utils/image_rejection_message.dart';

/// Opens the sheet with the ways to change the profile picture.
Future<void> showAvatarOptions(BuildContext context, UserProfile profile) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => AvatarOptionsSheet(profile: profile),
  );
}

/// Take a photo, choose one from the phone, or (for an account that signs in
/// with Google) tick "Sync from Google account" to use and follow that
/// account's photo.
class AvatarOptionsSheet extends ConsumerStatefulWidget {
  /// The profile as it was when the sheet opened; the sheet follows changes.
  final UserProfile profile;

  const AvatarOptionsSheet({super.key, required this.profile});

  @override
  ConsumerState<AvatarOptionsSheet> createState() => _AvatarOptionsSheetState();
}

class _AvatarOptionsSheetState extends ConsumerState<AvatarOptionsSheet> {
  bool _isBusy = false;

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: source);
    } catch (e) {
      // No camera, or the permission was refused.
      AppLogger.error('Could not open the image picker', e);
      if (mounted) AppPopup.showError(context, context.l10n.avatarFailed);
      return;
    }
    if (file == null || !mounted) return;

    final picked = file;
    await _run(() async {
      final PreparedImage image;
      try {
        image = await ImageCompressor.native.compress(
          picked,
          ImageUploadPolicy.avatar,
        );
      } on ImageRejectedException catch (e) {
        if (mounted) {
          AppPopup.showError(
            context,
            imageRejectionMessage(context.l10n, e.reason),
          );
        }
        // Already explained: no second message.
        return AvatarResult.cancelled;
      }
      return ref
          .read(avatarControllerProvider)
          .upload(image.bytes, mimeType: image.mimeType);
    }, closeWhenChanged: true);
  }

  /// Runs one change, shows how it ended, and with [closeWhenChanged]
  /// closes the sheet on success. The tick box keeps it open so the user
  /// sees the box change.
  Future<void> _run(
    Future<AvatarResult> Function() change, {
    bool closeWhenChanged = false,
  }) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final result = await change();
    if (!mounted) return;
    setState(() => _isBusy = false);

    final l10n = context.l10n;
    switch (result) {
      case AvatarResult.changed:
        AppPopup.showSuccess(context, l10n.avatarUpdated);
        if (closeWhenChanged) Navigator.pop(context);
      case AvatarResult.cancelled:
        break;
      case AvatarResult.noGooglePhoto:
        AppPopup.showInfo(context, l10n.avatarNoGooglePhoto);
      case AvatarResult.failed:
        showFailure(context, fallback: l10n.avatarFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final controller = ref.watch(avatarControllerProvider);
    // The newest profile, so the tick box moves as soon as the change is saved.
    final profile =
        ref.watch(userProfileProvider).valueOrNull ?? widget.profile;
    final hasOwnPicture =
        profile.avatarUrl != null && !profile.avatarFromGoogle;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keeps its height, so the rows do not jump when it appears.
          SizedBox(
            height: 4,
            child: _isBusy ? const LinearProgressIndicator() : null,
          ),
          ListTile(
            enabled: !_isBusy,
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(l10n.avatarTakePhoto),
            onTap: () => _pick(ImageSource.camera),
          ),
          ListTile(
            enabled: !_isBusy,
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.avatarChooseFromStorage),
            onTap: () => _pick(ImageSource.gallery),
          ),
          if (profile.signsInWithGoogle)
            CheckboxListTile(
              enabled: !_isBusy,
              value: profile.avatarFromGoogle,
              secondary: const Icon(Icons.sync),
              title: Text(l10n.avatarSyncFromGoogle),
              subtitle: Text(
                l10n.avatarSyncHelp,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              onChanged: (ticked) =>
                  _run(() => controller.setGoogleSync(ticked ?? false)),
            ),
          if (hasOwnPicture)
            ListTile(
              enabled: !_isBusy,
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text(
                l10n.avatarRemove,
                style: TextStyle(color: colors.danger),
              ),
              onTap: () => _run(controller.remove, closeWhenChanged: true),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
