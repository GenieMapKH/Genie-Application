import 'package:flutter/material.dart';

/// The route that presents a property's detail sheet over whatever opened it.
///
/// Opened from a card, the sheet is a [Hero] and grows out of that card.
/// Opened from the recommendations of another sheet (which is itself a hero,
/// so its tiles cannot be heroes too), it replaces that sheet with
/// `pushReplacement` and grows out of [origin], the tapped tile's rectangle.
/// The dimmed backdrop is handed from one sheet to the next so it never
/// flashes darker or lighter in between.
class PropertyDetailRoute extends PageRouteBuilder<void> {
  PropertyDetailRoute({required Widget page, Rect? origin})
    : super(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
              origin,
            ),
      );

  /// Share of the screen height the sheet covers, bottom aligned.
  static const double sheetHeightFactor = 0.9;

  static const Curve _curve = Cubic(0.16, 1.0, 0.3, 1.0);
  static const double _scrimOpacity = 0.25;

  /// Only another detail sheet takes over the backdrop; a dialog or the chat
  /// page opened from the sheet leaves it as it is.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PropertyDetailRoute;

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Rect? origin,
  ) {
    final curved = animation.drive(CurveTween(curve: _curve));
    Widget page = FadeTransition(opacity: curved, child: child);
    if (origin != null) {
      final screen = MediaQuery.sizeOf(context);
      final target = Rect.fromLTWH(
        0,
        screen.height * (1 - sheetHeightFactor),
        screen.width,
        screen.height * sheetHeightFactor,
      );
      page = AnimatedBuilder(
        animation: curved,
        child: page,
        builder: (_, page) => Transform(
          transform: _growFrom(
            origin,
            target,
            // Closing goes straight down, not back into a tile that is gone.
            animation.status == AnimationStatus.reverse ? 1 : curved.value,
          ),
          child: page,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([animation, secondaryAnimation]),
            builder: (_, _) => ColoredBox(
              color: Colors.black.withValues(
                alpha:
                    _scrimOpacity *
                    animation.value *
                    (1 - secondaryAnimation.value),
              ),
            ),
          ),
        ),
        page,
      ],
    );
  }

  /// Maps the settled sheet [target] onto the rectangle [t] of the way from
  /// [origin] to it.
  static Matrix4 _growFrom(Rect origin, Rect target, double t) {
    final now = Rect.lerp(origin, target, t)!;
    return Matrix4.translationValues(now.left, now.top, 0) *
        Matrix4.diagonal3Values(
          now.width / target.width,
          now.height / target.height,
          1,
        ) *
        Matrix4.translationValues(-target.left, -target.top, 0);
  }
}
