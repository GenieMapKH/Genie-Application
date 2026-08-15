import 'package:flutter/material.dart';

/// Direction for page transitions.
enum SlideDirection {
  fromRight,
  fromLeft,
  none,
}

/// A unified, consistent page route transition across the entire Genie app.
/// Implements a high-performance shared-axis slide and fade with matching reverse pop transitions.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  AppPageRoute({
    required this.page,
    this.direction = SlideDirection.fromRight,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 260),
    super.reverseTransitionDuration = const Duration(milliseconds: 240),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Primary transition for incoming screen
            final primaryAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            Offset beginOffset;
            switch (direction) {
              case SlideDirection.fromRight:
                beginOffset = const Offset(0.08, 0.0);
                break;
              case SlideDirection.fromLeft:
                beginOffset = const Offset(-0.08, 0.0);
                break;
              case SlideDirection.none:
                beginOffset = Offset.zero;
                break;
            }

            final slideIn = Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(primaryAnimation);

            final fadeIn = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
              ),
            );

            // Secondary transition for screen being covered
            final secondaryAnimationCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final exitOffset = direction == SlideDirection.fromLeft
                ? const Offset(0.04, 0.0)
                : const Offset(-0.04, 0.0);

            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: exitOffset,
            ).animate(secondaryAnimationCurved);

            return SlideTransition(
              position: slideOut,
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.88)
                    .animate(secondaryAnimationCurved),
                child: SlideTransition(
                  position: slideIn,
                  child: FadeTransition(
                    opacity: fadeIn,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
