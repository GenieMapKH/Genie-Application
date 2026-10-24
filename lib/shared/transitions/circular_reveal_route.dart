import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A full page revealed by a circle that grows out of [origin], the
/// on-screen rectangle of what was tapped (an avatar), until it covers the
/// screen. Closing, the circle shrinks back into [origin].
class CircularRevealRoute<T> extends PageRouteBuilder<T> {
  CircularRevealRoute({required Widget page, required Rect origin})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (context, animation, _, child) {
          final curved = animation.drive(CurveTween(curve: _curve));
          final screen = Offset.zero & MediaQuery.sizeOf(context);
          return ClipPath(
            clipper: _CircleClipper(
              animation: curved,
              center: origin.center,
              startRadius: origin.shortestSide / 2,
              endRadius: _farthestCorner(origin.center, screen),
            ),
            child: AnimatedBuilder(
              animation: curved,
              child: child,
              // The page zooms out of the avatar as the circle opens.
              builder: (_, page) => Transform.scale(
                scale: _startScale + (1 - _startScale) * curved.value,
                origin: origin.center - screen.center,
                child: page,
              ),
            ),
          );
        },
      );

  static const Curve _curve = Curves.easeInOutCubic;
  static const double _startScale = 0.85;

  /// How far [center] is from the corner of [screen] furthest from it, the
  /// radius that just covers the screen.
  static double _farthestCorner(Offset center, Rect screen) => [
    screen.topLeft,
    screen.topRight,
    screen.bottomLeft,
    screen.bottomRight,
  ].map((corner) => (corner - center).distance).reduce(math.max);
}

class _CircleClipper extends CustomClipper<Path> {
  final Animation<double> animation;
  final Offset center;
  final double startRadius;
  final double endRadius;

  _CircleClipper({
    required this.animation,
    required this.center,
    required this.startRadius,
    required this.endRadius,
  }) : super(reclip: animation);

  @override
  Path getClip(Size size) {
    final radius = startRadius + (endRadius - startRadius) * animation.value;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.center != center ||
      old.startRadius != startRadius ||
      old.endRadius != endRadius;
}
