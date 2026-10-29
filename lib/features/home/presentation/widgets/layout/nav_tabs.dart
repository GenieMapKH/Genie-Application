import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/device/app_haptics.dart';
import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// One tab of the bottom navigation.
class NavTab {
  final int index;
  final String iconAsset;
  final String Function(AppLocalizations l10n) label;

  const NavTab(this.index, this.iconAsset, this.label);
}

/// The tabs, in the order the bar shows them. Shared by both looks of the
/// bar so they can never disagree.
final List<NavTab> mainNavTabs = [
  NavTab(MainTab.explore, 'assets/icons/explore.svg', (l) => l.navExplore),
  NavTab(MainTab.feed, 'assets/icons/feed.svg', (l) => l.navFeed),
  NavTab(MainTab.saved, 'assets/icons/saved.svg', (l) => l.navSaved),
  NavTab(MainTab.chat, 'assets/icons/chat.svg', (l) => l.navChat),
  NavTab(
    MainTab.myProperties,
    'assets/icons/property.svg',
    (l) => l.navListings,
  ),
  NavTab(MainTab.user, 'assets/icons/user.svg', (l) => l.navUser),
];

/// A tab was tapped: every tab but Explore shows the user's own data, so a
/// guest is asked to sign in first. Picking a different tab clicks softly.
void selectMainTab(BuildContext context, WidgetRef ref, int index) {
  if (index != MainTab.explore && !requireSignIn(context, ref)) return;
  if (ref.read(mainNavProvider).currentIndex != index) AppHaptics.selection();
  ref.read(mainNavProvider.notifier).setIndex(index);
}

/// [icon] with the unread-message count over its corner, on the Chat tab.
class NavUnreadBadge extends ConsumerWidget {
  final int tabIndex;
  final Widget icon;

  const NavUnreadBadge({super.key, required this.tabIndex, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = tabIndex == MainTab.chat
        ? ref.watch(unreadCountProvider)
        : 0;
    if (unreadCount <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
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
}
