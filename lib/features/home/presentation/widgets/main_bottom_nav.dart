import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/core/theme/app_colors.dart';

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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNavItem(
              context,
              ref,
              0,
              'assets/icons/explore.svg',
              l10n.navExplore,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              1,
              'assets/icons/saved.svg',
              l10n.navSaved,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              2,
              'assets/icons/chat.svg',
              l10n.navChat,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              3,
              'assets/icons/property.svg',
              l10n.navMyProperties,
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              4,
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

    final unreadCount = index == 2 ? ref.watch(unreadCountProvider) : 0;

    Widget iconWidget = SvgPicture.asset(
      iconPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    if (index == 2 && unreadCount > 0) {
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

    return TactileButton(
      onPressed: () {
        // Every tab but Explore shows the user's own data.
        if (index != 0 && !requireSignIn(context, ref)) return;
        ref.read(mainNavProvider.notifier).setIndex(index);
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Text(
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
          ],
        ),
      ),
    );
  }
}
