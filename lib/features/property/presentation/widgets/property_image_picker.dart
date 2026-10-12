import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class PropertyImagePicker extends StatelessWidget {
  final List<XFile> selectedPhotos;
  final void Function(ImageSource source) onPhotoPicked;
  final void Function(int index) onPhotoRemoved;

  const PropertyImagePicker({
    super.key,
    required this.selectedPhotos,
    required this.onPhotoPicked,
    required this.onPhotoRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    selectedPhotos.length < 4 ? 4 : selectedPhotos.length + 1,
                    (index) {
                      final boxSize =
                          (MediaQuery.sizeOf(context).width - 32 - 36) / 4;
                      final isPhoto = index < selectedPhotos.length;
                      return Container(
                        width: boxSize,
                        height: boxSize,
                        margin: EdgeInsets.only(
                          right:
                              index ==
                                  (selectedPhotos.length < 4
                                      ? 3
                                      : selectedPhotos.length)
                              ? 0
                              : 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          border: isPhoto
                              ? null
                              : Border.all(
                                  color: context.colors.iconSubtle,
                                  style: BorderStyle.solid,
                                ),
                          borderRadius: BorderRadius.circular(8.0),
                          image: isPhoto
                              ? DecorationImage(
                                  image: kIsWeb
                                      ? NetworkImage(selectedPhotos[index].path)
                                            as ImageProvider
                                      : FileImage(
                                          File(selectedPhotos[index].path),
                                        ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: isPhoto
                            ? Stack(
                                children: [
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => onPhotoRemoved(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  Icons.add,
                                  color: context.colors.textHint,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.propertyAddAtLeast3ClearPhotos,
                      style: GoogleFonts.inter(
                        color: context.colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onPhotoPicked(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: context.colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        backgroundColor: context.colors.surface,
                      ),
                      child: Text(
                        context.l10n.propertyOpenCamera,
                        style: GoogleFonts.inter(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => onPhotoPicked(ImageSource.gallery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        context.l10n.propertyUploadPropertyPhotos,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
