import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tilomnov/core/media/image_compressor.dart';
import 'package:tilomnov/core/media/image_upload_policy.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// A picture the user chose to send.
typedef PickedChatImage = ({Uint8List bytes, String name, String mimeType});

/// Asks where the picture should come from, then returns it compressed to
/// a small JPEG so it sends quickly. Null if the user backs out. Throws
/// [ImageRejectedException] for a picture that is too large or unreadable.
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

  final file = await ImagePicker().pickImage(source: source);
  if (file == null) return null;

  final image = await ImageCompressor.native.compress(
    file,
    ImageUploadPolicy.chatPhoto,
  );
  return (bytes: image.bytes, name: image.name, mimeType: image.mimeType);
}
