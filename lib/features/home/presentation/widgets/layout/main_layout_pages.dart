import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';

import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/home/presentation/widgets/layout/kept_tab_pages.dart';
import 'package:genie/features/profile/presentation/screens/user_profile_page.dart';
import 'package:genie/features/chat/presentation/screens/chat_list_page.dart';
import 'package:genie/features/property/presentation/screens/my_properties_page.dart';
import 'package:genie/features/property/presentation/screens/saved_properties_page.dart';

/// The full-screen pages that slide in over the map for the "Saved", "Chat",
/// "My Properties" and "User" tabs. Each is kept once opened ([KeptTabPages]).
class MainLayoutPages extends ConsumerWidget {
  final MainNavState navState;

  const MainLayoutPages({super.key, required this.navState});

  static const int _savedPropertiesIndex = 1;
  static const int _chatIndex = 2;
  static const int _myPropertiesIndex = 3;
  static const int _userProfileIndex = 4;

  static bool _isPage(int index) =>
      index >= _savedPropertiesIndex && index <= _userProfileIndex;

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
          pageBuilder: (context, index) => switch (index) {
            _savedPropertiesIndex => SavedPropertiesPage(
              isEmbedded: true,
              onBackPressed: onBack,
            ),
            _chatIndex => ChatListPage(isEmbedded: true, onBackPressed: onBack),
            _myPropertiesIndex => MyPropertiesPage(
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
