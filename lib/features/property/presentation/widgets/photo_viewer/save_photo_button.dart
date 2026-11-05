import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/property/data/services/property_photo_saver.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

final propertyPhotoSaverProvider = Provider<PropertyPhotoSaver>(
  (ref) => const PropertyPhotoSaver(),
);

/// The viewer's download button: saves the photo shown, logo burned in, to
/// the phone's gallery. A spinner takes its place while saving.
class SavePhotoButton extends ConsumerStatefulWidget {
  final String url;
  final String fileName;

  const SavePhotoButton({super.key, required this.url, required this.fileName});

  @override
  ConsumerState<SavePhotoButton> createState() => _SavePhotoButtonState();
}

class _SavePhotoButtonState extends ConsumerState<SavePhotoButton> {
  bool _saving = false;

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(propertyPhotoSaverProvider)
          .save(widget.url, name: widget.fileName);
      if (!mounted) return;
      switch (result) {
        case PhotoSaveResult.saved:
          AppPopup.showSuccess(context, l10n.propertyShareImageSaved);
        case PhotoSaveResult.accessDenied:
          AppPopup.showError(context, l10n.propertySharePhotosDenied);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Saving a listing photo failed', e, stackTrace);
      if (mounted) {
        AppPopup.showError(context, l10n.propertyShareImageSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saving) {
      return const SizedBox.square(
        dimension: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return IconButton(
      onPressed: _save,
      tooltip: context.l10n.propertySavePhoto,
      icon: const Icon(Icons.download_rounded),
      color: Colors.white,
    );
  }
}
