import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SlideDirection { fromRight, fromLeft, none }

class AppTransitionPage<T> extends CustomTransitionPage<T> {
  AppTransitionPage({
    required super.child,
    super.key,
    SlideDirection direction = SlideDirection.fromRight,
  }) : super(
         transitionDuration: const Duration(milliseconds: 340),
         reverseTransitionDuration: const Duration(milliseconds: 280),
         opaque: true,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

           return Container(
             color: Colors.white,
             child: SlideTransition(
               position: slideIn,
               child: FadeTransition(opacity: fadeIn, child: child),
             ),
           );
         },
       );
}
