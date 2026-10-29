import 'package:flutter/material.dart';

/// The route that opens a listing's edit form out of the card that was tapped,
/// the way the detail sheet grows out of a card on the Saved and Feed tabs.
///
/// The form is revealed through a rounded window that grows from the card's
/// rectangle ([origin]) to the whole screen while the form slides into place,
/// so it is never stretched. Closing shrinks it back into the card.
class PropertyEditRoute extends PageRouteBuilder<void> {
  PropertyEditRoute({required Widget page, required Rect origin})
    : super(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (context, animation, _, child) =>
            _buildTransition(context, animation, child, origin),
      );

  static const Curve _curve = Cubic(0.16, 1.0, 0.3, 1.0);
  static const double _cardRadius = 12;
  static const double _scrimOpacity = 0.25;

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
    Rect origin,
  ) {
    final curved = animation.drive(CurveTween(curve: _curve));
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    // The form is solid, so it fades in over the card instead of covering it
    // with a hard edge.
    final fade = animation.drive(
      CurveTween(curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, _) => ColoredBox(
              color: Colors.black.withValues(
                alpha: _scrimOpacity * animation.value,
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: curved,
          child: FadeTransition(opacity: fade, child: child),
          builder: (_, form) {
            final now = Rect.lerp(origin, screen, curved.value)!;
            return ClipRRect(
              clipper: _WindowClipper(
                now,
                _cardRadius * (1 - curved.value.clamp(0.0, 1.0)),
              ),
              child: Transform.translate(offset: now.topLeft, child: form),
            );
          },
        ),
      ],
    );
  }
}

/// Clips to [window] in the route's own coordinates.
class _WindowClipper extends CustomClipper<RRect> {
  final Rect window;
  final double radius;

  const _WindowClipper(this.window, this.radius);

  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(window, Radius.circular(radius));

  @override
  bool shouldReclip(_WindowClipper oldClipper) =>
      oldClipper.window != window || oldClipper.radius != radius;
}
