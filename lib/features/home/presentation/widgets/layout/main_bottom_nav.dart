import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/shared/widgets/buttons/tactile_button.dart';
import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/shared/widgets/media/tinted_svg.dart';

class MainBottomNav extends ConsumerWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavProvider).currentIndex;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final colors = context.colors;
    final l10n = context.l10n;

    Widget navContent = Container(
      height: 98.0,
      decoration: BoxDecoration(
        // Translucent on iOS, where the map shows through the blur behind it.
        color: isIOS ? colors.surface.withValues(alpha: 0.85) : colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNavItem(
              context,
              ref,
              MainTab.explore,
              'assets/icons/explore.svg',
              l10n.navExplore,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              MainTab.feed,
              'assets/icons/feed.svg',
              l10n.navFeed,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              MainTab.saved,
              'assets/icons/saved.svg',
              l10n.navSaved,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              MainTab.chat,
              'assets/icons/chat.svg',
              l10n.navChat,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              MainTab.myProperties,
              'assets/icons/property.svg',
              l10n.navListings,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              MainTab.user,
              'assets/icons/user.svg',
              l10n.navUser,
              currentIndex,
            ),
          ],
        ),
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
    int index,
    String iconPath,
    String label,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? context.colors.primaryStrong
        : context.colors.textMuted;

    final unreadCount = index == MainTab.chat
        ? ref.watch(unreadCountProvider)
        : 0;

    Widget iconWidget = TintedSvg(
      iconPath,
      width: 24,
      height: 24,
      color: color,
    );

    if (index == MainTab.chat && unreadCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    // The six tabs share the width: fixed widths overflow narrow phones.
    return Expanded(
      child: TactileButton(
        onPressed: () {
          // Every tab but Explore shows the user's own data.
          if (index != MainTab.explore && !requireSignIn(context, ref)) return;
          ref.read(mainNavProvider.notifier).setIndex(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
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
