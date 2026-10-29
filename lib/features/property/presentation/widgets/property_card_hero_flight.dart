import 'package:flutter/widgets.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/core/theme/app_shapes.dart';

/// How a listing card flies to the same listing's card on the next page
/// (the feed's wide card to a profile's narrow one, and back). Each card
/// keeps its own layout, scaled to the flying size, and the one being
/// opened fades in over the other. Laid out at every in-between size
/// instead, as Flutter does by default, its text re-wraps on every frame.
///
/// Both heroes must use this builder; a flight to anything else (the detail
/// sheet) is Flutter's default.
Widget propertyCardFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final fromHero = fromHeroContext.widget as Hero;
  final toHero = toHeroContext.widget as Hero;
  final fromSize = _sizeOf(fromHeroContext);
  final toSize = _sizeOf(toHeroContext);
  if (fromHero.flightShuttleBuilder != toHero.flightShuttleBuilder ||
      fromSize == null ||
      toSize == null) {
    return _defaultFlight(animation, direction, fromHeroContext, toHeroContext);
  }

  // The route animation runs from the lower page (0) to the upper one (1)
  // whichever way the flight goes.
  final pushing = direction == HeroFlightDirection.push;
  final colors = toHeroContext.colors;

  return IgnorePointer(
    child: DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: AppShapes.continuous(
          16,
          side: BorderSide(color: colors.divider),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ScaledFace(
            size: pushing ? fromSize : toSize,
            child: (pushing ? fromHero : toHero).child,
          ),
          FadeTransition(
            opacity: animation,
            child: _ScaledFace(
              size: pushing ? toSize : fromSize,
              child: (pushing ? toHero : fromHero).child,
            ),
          ),
        ],
      ),
    ),
  );
}

Size? _sizeOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
  return box.size;
}

/// One card laid out at its own size, scaled to the flying width from the
/// top; what no longer fits below is cut off.
class _ScaledFace extends StatelessWidget {
  final Size size;
  final Widget child;

  const _ScaledFace({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(16),
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox.fromSize(size: size, child: child),
      ),
    );
  }
}

/// What Flutter does without a builder: the destination hero, with the
/// safe-area padding moving from one page's to the other's.
Widget _defaultFlight(
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final child = (toHeroContext.widget as Hero).child;
  final fromMedia = MediaQuery.maybeOf(fromHeroContext);
  final toMedia = MediaQuery.maybeOf(toHeroContext);
  if (fromMedia == null || toMedia == null) return child;
  final padding = direction == HeroFlightDirection.push
      ? EdgeInsetsTween(begin: fromMedia.padding, end: toMedia.padding)
      : EdgeInsetsTween(begin: toMedia.padding, end: fromMedia.padding);

  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) => MediaQuery(
      data: toMedia.copyWith(padding: padding.evaluate(animation)),
      child: child!,
    ),
    child: child,
  );
}
