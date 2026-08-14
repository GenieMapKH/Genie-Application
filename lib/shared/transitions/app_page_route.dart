import 'package:flutter/material.dart';

/// A unified, consistent page route transition across the entire Genie app.
/// Implements a high-performance shared-axis slide and fade with matching reverse pop transitions.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({
    required this.page,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 300),
    super.reverseTransitionDuration = const Duration(milliseconds: 280),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Primary transition for incoming screen
            final primaryAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideIn = Tween<Offset>(
              begin: const Offset(0.08, 0.0),
              end: Offset.zero,
            ).animate(primaryAnimation);

            // Secondary transition for screen being covered
            final secondaryAnimationCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.04, 0.0),
            ).animate(secondaryAnimationCurved);

            return SlideTransition(
              position: slideOut,
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.88)
                    .animate(secondaryAnimationCurved),
                child: SlideTransition(
                  position: slideIn,
                  child: FadeTransition(
                    opacity: primaryAnimation,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
