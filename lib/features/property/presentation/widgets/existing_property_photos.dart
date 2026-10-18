import 'package:genie/shared/widgets/media/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// The photos a listing already has, shown above the picker while it is being
/// edited: each can be taken off, and new photos are added after them.
/// Nothing changes on the listing until the edit is saved, and until then
/// the owner can bring back what they took off.
class ExistingPropertyPhotos extends StatelessWidget {
  final List<String> urls;

  /// How many saved photos were taken off in this edit.
  final int removedCount;
  final ValueChanged<String> onRemove;
  final VoidCallback onRestore;

  const ExistingPropertyPhotos({
    super.key,
    required this.urls,
    required this.removedCount,
    required this.onRemove,
    required this.onRestore,
  });

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.propertyCurrentPhotos(urls.length),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.colors.textMuted,
                ),
              ),
            ),
            if (removedCount > 0)
              TextButton(
                onPressed: onRestore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.l10n.propertyRestoreRemovedPhotos(removedCount),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (urls.isNotEmpty)
          SizedBox(
            height: _size,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _SavedPhoto(
                url: urls[index],
                size: _size,
                onRemove: () => onRemove(urls[index]),
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SavedPhoto extends StatelessWidget {
  final String url;
  final double size;
  final VoidCallback onRemove;

  const _SavedPhoto({
    required this.url,
    required this.size,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppNetworkImage(
            url: url,
            width: size,
            height: size,
            placeholder: ColoredBox(color: context.colors.surfaceMuted),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Semantics(
            button: true,
            label: context.l10n.propertyRemovePhoto,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
