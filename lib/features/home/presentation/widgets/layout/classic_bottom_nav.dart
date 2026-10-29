import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/nav_tabs.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/shared/widgets/media/tinted_svg.dart';

/// The full-width bottom bar shown on every phone whose own interface is not
/// glass (see `GlassBottomNav` for those that are).
class ClassicBottomNav extends ConsumerWidget {
  const ClassicBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavProvider).currentIndex;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final colors = context.colors;

    Widget navContent = Container(
      height: 98.0,
      decoration: BoxDecoration(
        // Translucent on iOS, where the map shows through the blur behind it.
        color: isIOS ? colors.surface.withValues(alpha: 0.85) : colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1.0),
        ),
      ),
      // Each tab takes its whole slot of the bar, so a tap beside or below
      // the icon still lands on it.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final tab in mainNavTabs)
            _buildNavItem(context, ref, tab, currentIndex),
        ],
      ),
    );

    if (isIOS) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: navContent,
        ),
      );
    }

    return navContent;
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    NavTab tab,
    int currentIndex,
  ) {
    final isSelected = currentIndex == tab.index;
    final color = isSelected
        ? context.colors.primaryStrong
        : context.colors.textMuted;

    // The six tabs share the width: fixed widths overflow narrow phones.
    return Expanded(
      child: TactileButton(
        onPressed: () => selectMainTab(context, ref, tab.index),
        child: Column(
          children: [
            const SizedBox(height: 16),
            NavUnreadBadge(
              tabIndex: tab.index,
              icon: TintedSvg(
                tab.iconAsset,
                width: 24,
                height: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                tab.label(context.l10n),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
