import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/owner_display_name.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';

/// Keeps the avatar as the origin of the publisher profile's reveal.
class FeedPostHeader extends StatefulWidget {
  final PropertyModel property;
  final ValueChanged<Rect> onOpenOwner;

  const FeedPostHeader({
    super.key,
    required this.property,
    required this.onOpenOwner,
  });

  @override
  State<FeedPostHeader> createState() => _FeedPostHeaderState();
}

class _FeedPostHeaderState extends State<FeedPostHeader> {
  final _avatarKey = GlobalKey();

  void _openOwner() {
    final box = _avatarKey.currentContext!.findRenderObject()! as RenderBox;
    widget.onOpenOwner(box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final colors = context.colors;
    final l10n = context.l10n;
    final name = ownerDisplayName(l10n, property.ownerName);
    final listed = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format((property.publishedAt ?? property.createdAt).toLocal());

    return InkWell(
      onTap: property.ownerId == null ? null : _openOwner,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            UserAvatar(
              key: _avatarKey,
              name: name,
              avatarUrl: property.ownerAvatarUrl,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.feedListedOn(listed),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (property.ownerId != null)
              Icon(LucideIcons.chevronRight, size: 20, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
