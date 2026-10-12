import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/image_mime_type.dart';

/// A picture the user chose to send.
typedef PickedChatImage = ({Uint8List bytes, String name, String mimeType});

/// Asks where the picture should come from, then returns it, scaled down so
/// it sends quickly. Null if the user backs out.
Future<PickedChatImage?> pickChatImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(context.l10n.chatPhotoLibrary),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(context.l10n.chatCamera),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  if (file == null) return null;

  return (
    bytes: await file.readAsBytes(),
    name: file.name,
    mimeType: file.mimeType ?? imageMimeTypeOf(file.name),
  );
}
