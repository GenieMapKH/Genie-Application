import 'package:flutter/material.dart';
import 'package:tilomnov/features/admin/presentation/admin_dashboard_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

import 'package:tilomnov/features/feed/presentation/screens/feed_page.dart';
import 'package:tilomnov/features/home/presentation/providers/main_nav_provider.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/kept_tab_pages.dart';
import 'package:tilomnov/features/profile/presentation/screens/user_profile_page.dart';
import 'package:tilomnov/features/chat/presentation/screens/chat_list_page.dart';
import 'package:tilomnov/features/property/presentation/screens/my_properties_page.dart';
import 'package:tilomnov/features/property/presentation/screens/saved_properties_page.dart';

/// The full-screen pages that slide in over the map for every tab but
/// Explore. Each is kept once opened ([KeptTabPages]).
class MainLayoutPages extends ConsumerWidget {
  final MainNavState navState;
  final bool isAdmin;

  const MainLayoutPages({
    super.key,
    required this.navState,
    this.isAdmin = false,
  });

  static bool _isPage(int index) =>
      index >= MainTab.feed && index <= MainTab.user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onBack() => ref.read(mainNavProvider.notifier).resetToHome();

    final bool isPageVisible = _isPage(navState.currentIndex);
    final bool isPrevVisible = _isPage(navState.previousIndex);

    return IgnorePointer(
      // Over the map: nothing here may take its touches while home is shown.
      ignoring: !isPageVisible,
      child: Container(
        // Opaque only while sliding between full-screen pages, so the map
        // stays visible when returning home.
        color: (isPageVisible && isPrevVisible)
            ? context.colors.background
            : null,
        child: KeptTabPages(
          current: navState.currentIndex,
          previous: navState.previousIndex,
          hasPage: _isPage,
          pageBuilder: (context, index) => isAdmin
              ? switch (index) {
                  AdminTab.services => const AdminDashboardPage(
                    section: AdminSection.services,
                  ),
                  AdminTab.account => const AdminDashboardPage(
                    section: AdminSection.account,
                  ),
                  AdminTab.activity => const AdminDashboardPage(
                    section: AdminSection.activity,
                  ),
                  AdminTab.financial => const AdminDashboardPage(
                    section: AdminSection.financial,
                  ),
                  _ => UserProfilePage(isEmbedded: true, onBackPressed: onBack),
                }
              : switch (index) {
                  MainTab.feed => FeedPage(
                    isEmbedded: true,
                    onBackPressed: onBack,
                  ),
                  MainTab.saved => SavedPropertiesPage(
                    isEmbedded: true,
                    onBackPressed: onBack,
                  ),
                  MainTab.chat => ChatListPage(
                    isEmbedded: true,
                    onBackPressed: onBack,
                  ),
                  MainTab.myProperties => MyPropertiesPage(
                    isEmbedded: true,
                    onBackPressed: onBack,
                  ),
                  _ => UserProfilePage(isEmbedded: true, onBackPressed: onBack),
                },
        ),
      ),
    );
  }
}
