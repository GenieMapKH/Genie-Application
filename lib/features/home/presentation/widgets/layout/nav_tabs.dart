import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
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
  final IconData icon;
  final String Function(AppLocalizations l10n) label;
  final bool showUnread;

  const NavTab(this.index, this.icon, this.label, {this.showUnread = false});

  Widget buildIcon(Color color) => Icon(icon, size: 24, color: color);
}

/// The tabs, in the order the bar shows them. Shared by both looks of the
/// bar so they can never disagree.
final List<NavTab> mainNavTabs = [
  NavTab(MainTab.explore, LucideIcons.compass, (l) => l.navExplore),
  NavTab(MainTab.feed, LucideIcons.newspaper, (l) => l.navFeed),
  NavTab(MainTab.saved, LucideIcons.bookmark, (l) => l.navSaved),
  NavTab(
    MainTab.chat,
    LucideIcons.messageCircle,
    (l) => l.navChat,
    showUnread: true,
  ),
  NavTab(MainTab.myProperties, LucideIcons.house, (l) => l.navListings),
  NavTab(MainTab.user, LucideIcons.userRound, (l) => l.navUser),
];

List<NavTab> navTabsFor({required bool isAdmin}) => isAdmin
    ? [
        mainNavTabs.first,
        NavTab(AdminTab.services, LucideIcons.server, (_) => 'Services'),
        NavTab(AdminTab.account, LucideIcons.userCog, (_) => 'Account'),
        NavTab(AdminTab.activity, LucideIcons.heartPulse, (_) => 'Activity'),
        NavTab(AdminTab.financial, LucideIcons.wallet, (_) => 'Financial'),
        NavTab(AdminTab.profile, LucideIcons.userRound, (_) => 'Profile'),
      ]
    : mainNavTabs;

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
