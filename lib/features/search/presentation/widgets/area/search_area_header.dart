import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/search/presentation/view_models/search_area_controller.dart';
import 'package:genie/features/search/presentation/view_models/search_selection.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/user_avatar.dart';

/// Top of the results panel: what is shown, how many listings, and a close
/// button.
class SearchAreaHeader extends StatelessWidget {
  /// Fixed so the sheet can rest collapsed at exactly this height.
  static const double height = 76;

  final SearchAreaState state;
  final VoidCallback onClose;

  const SearchAreaHeader({
    super.key,
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final target = state.target;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            _Leading(target: target),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              tooltip: context.l10n.searchCloseResults,
              icon: Icon(Icons.close_rounded, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final count = state.area.valueOrNull?.properties.length;
    final target = state.target;

    if (count == null) {
      return switch (target) {
        PlaceTarget() => target.place.secondaryText ?? '',
        PersonTarget() => l10n.searchListingCount(target.person.listingCount),
      };
    }
    return switch (target) {
      PlaceTarget() => l10n.searchPropertiesInArea(count),
      PersonTarget() => l10n.searchPropertiesByPerson(count),
    };
  }
}

class _Leading extends StatelessWidget {
  final SearchTarget target;

  const _Leading({required this.target});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (target) {
      PersonTarget(:final person) => UserAvatar(
        name: person.displayName,
        avatarUrl: person.avatarUrl,
        radius: 22,
      ),
      PlaceTarget() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.place_rounded, color: colors.primary),
      ),
    };
  }
}
