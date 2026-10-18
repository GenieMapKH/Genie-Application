import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/shared/transitions/app_page_route.dart';
import 'package:genie/shared/widgets/layout/app_header_bar.dart';

/// A full screen with the standard header on top of [child]: the frame of
/// every settings screen.
class AppPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  /// What the back arrow does. Defaults to leaving the screen.
  final VoidCallback? onBackPressed;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(title: title, onBackPressed: onBackPressed),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

extension AppPageNavigation on BuildContext {
  /// Opens [page] over everything, the bottom navigation bar included.
  Future<T?> pushPage<T>(Widget page) {
    return Navigator.of(
      this,
      rootNavigator: true,
    ).push<T>(AppPageRoute<T>(page: page));
  }
}
