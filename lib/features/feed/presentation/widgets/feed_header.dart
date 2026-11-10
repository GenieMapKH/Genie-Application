import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_header_bar.dart';

class FeedHeader extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback onExplore;
  final VoidCallback onFilter;
  final int filterCount;

  const FeedHeader({
    super.key,
    this.onBackPressed,
    required this.onExplore,
    required this.onFilter,
    this.filterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return ColoredBox(
      color: colors.background,
      child: Column(
        children: [
          AppHeaderBar(
            title: l10n.feedTitle,
            onBackPressed: onBackPressed,
            showBackButton:
                onBackPressed != null || Navigator.of(context).canPop(),
            trailing: IconButton(
              onPressed: onExplore,
              tooltip: l10n.feedExplore,
              style: IconButton.styleFrom(foregroundColor: colors.textPrimary),
              icon: const Icon(Icons.explore_outlined),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.feedSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.5,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: colors.highlight,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  l10n.profileFollowing,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onFilter,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: Text(
                            filterCount == 0
                                ? l10n.filterTitle
                                : '${l10n.filterTitle} ($filterCount)',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: filterCount == 0
                                ? colors.textSecondary
                                : colors.accent,
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 1, color: colors.divider),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
