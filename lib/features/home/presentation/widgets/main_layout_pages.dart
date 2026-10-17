import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';

import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/profile/presentation/screens/user_profile_page.dart';
import 'package:genie/features/chat/presentation/screens/chat_list_page.dart';
import 'package:genie/features/property/presentation/screens/my_properties_page.dart';
import 'package:genie/features/property/presentation/screens/saved_properties_page.dart';

/// The full-screen pages that slide in over the map for the "Saved", "My Properties" and
/// "User" tabs.
class MainLayoutPages extends ConsumerWidget {
  final MainNavState navState;

  const MainLayoutPages({super.key, required this.navState});

  static const int _savedPropertiesIndex = 1;
  static const int _chatIndex = 2;
  static const int _myPropertiesIndex = 3;
  static const int _userProfileIndex = 4;

  String get _currentKey => switch (navState.currentIndex) {
    _savedPropertiesIndex => 'saved_properties',
    _chatIndex => 'chat_list',
    _myPropertiesIndex => 'my_properties',
    _userProfileIndex => 'user_profile',
    _ => 'empty',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onBack() => ref.read(mainNavProvider.notifier).resetToHome();

    final bool isPageVisible =
        navState.currentIndex == _savedPropertiesIndex ||
        navState.currentIndex == _chatIndex ||
        navState.currentIndex == _myPropertiesIndex ||
        navState.currentIndex == _userProfileIndex;
    final bool isPrevVisible =
        navState.previousIndex == _savedPropertiesIndex ||
        navState.previousIndex == _chatIndex ||
        navState.previousIndex == _myPropertiesIndex ||
        navState.previousIndex == _userProfileIndex;

    return Container(
      // Opaque only while sliding between full-screen pages, so the map
      // stays visible when returning home.
      color: (isPageVisible && isPrevVisible)
          ? context.colors.background
          : Colors.transparent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: _buildTransition,
        child: switch (navState.currentIndex) {
          _savedPropertiesIndex => SavedPropertiesPage(
            key: const ValueKey('saved_properties'),
            isEmbedded: true,
            onBackPressed: onBack,
          ),
          _chatIndex => ChatListPage(
            key: const ValueKey('chat_list'),
            isEmbedded: true,
            onBackPressed: onBack,
          ),
          _myPropertiesIndex => MyPropertiesPage(
            key: const ValueKey('my_properties'),
            isEmbedded: true,
            onBackPressed: onBack,
          ),
          _userProfileIndex => UserProfilePage(
            key: const ValueKey('user_profile'),
            isEmbedded: true,
            onBackPressed: onBack,
          ),
          _ => const SizedBox.shrink(key: ValueKey('empty')),
        },
      ),
    );
  }

  /// Slides pages in from the direction that matches the tab order.
  Widget _buildTransition(Widget child, Animation<double> animation) {
    final key = child.key as ValueKey<String>?;
    final bool isIncoming = key?.value == _currentKey;
    final bool forward = navState.currentIndex > navState.previousIndex;

    final Offset begin = forward
        ? (isIncoming ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0))
        : (isIncoming ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0));

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }
}
