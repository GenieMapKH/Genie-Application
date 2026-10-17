import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// The photos a listing already has, shown read-only above the picker while
/// it is being edited: new photos are added after them.
class ExistingPropertyPhotos extends StatelessWidget {
  final List<String> urls;

  const ExistingPropertyPhotos({super.key, required this.urls});

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.propertyCurrentPhotos(urls.length),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.colors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _size,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: urls[index],
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                placeholder: (context, _) =>
                    ColoredBox(color: context.colors.surfaceMuted),
                errorWidget: (context, _, _) => ColoredBox(
                  color: context.colors.surfaceMuted,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.colors.textHint,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
