import 'package:flutter/material.dart';

/// Direction for page transitions.
enum SlideDirection { fromRight, fromLeft, none }

/// A unified, consistent page route transition across the entire Tilomnov app.
/// Implements a high-performance shared-axis slide and fade with matching reverse pop transitions
/// and a solid backdrop (the theme's page colour) to eliminate any sub-pixel seam/flash during route replacement.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  AppPageRoute({
    required this.page,
    this.direction = SlideDirection.fromRight,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 340),
    super.reverseTransitionDuration = const Duration(milliseconds: 280),
    super.opaque = true,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Primary transition for incoming screen
           final primaryAnimation = CurvedAnimation(
             parent: animation,
             curve: const Cubic(0.16, 1.0, 0.3, 1.0),
             reverseCurve: Curves.easeOutCubic,
           );

           Offset beginOffset;
           switch (direction) {
             case SlideDirection.fromRight:
               beginOffset = const Offset(0.06, 0.0);
               break;
             case SlideDirection.fromLeft:
               beginOffset = const Offset(-0.06, 0.0);
               break;
             case SlideDirection.none:
               beginOffset = Offset.zero;
               break;
           }

           final slideIn = Tween<Offset>(
             begin: beginOffset,
             end: Offset.zero,
           ).animate(primaryAnimation);

           final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
             CurvedAnimation(
               parent: animation,
               curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
             ),
           );

           // Wrap in a solid canvas of the page colour to completely prevent any underlying
           // window surface from flashing through transparent seams during transitions
           return Container(
             color: Theme.of(context).scaffoldBackgroundColor,
             child: SlideTransition(
               position: slideIn,
               child: FadeTransition(opacity: fadeIn, child: child),
             ),
           );
         },
       );
}
