import 'package:flutter/widgets.dart';

/// How things move in the app. Springs are described the way Apple describes
/// them (a perceived duration and a bounce, see
/// [SpringDescription.withDurationAndBounce]) so a motion can be matched to
/// the system's own: no bounce for anything that simply arrives, a little for
/// direct responses to a touch, more only for a moment worth celebrating.
abstract final class AppMotion {
  /// Things that arrive or settle: pages, sheets, panels. Apple's default.
  static final smooth = SpringDescription.withDurationAndBounce();

  /// A direct answer to a touch: a released press, a moved selection.
  static final snappy = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 350),
    bounce: 0.15,
  );

  /// A small celebration: a listing saved, a tab icon picked.
  static final bouncy = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 450),
    bounce: 0.3,
  );

  /// Following a finger down: quick and without overshoot.
  static final press = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 150),
  );

  /// The tab bar's selection sliding to the picked tab.
  static final selection = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 420),
    bounce: 0.2,
  );

  /// Cross-fades, where nothing travels.
  static const fade = Duration(milliseconds: 180);

  /// Ease-out for the timed (non-spring) motions that remain.
  static const easeOut = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Whether the person asked for less motion: Android's "Remove
  /// animations" (reported through [MediaQuery]) or iOS's Reduce Motion,
  /// which Flutter only reports on the platform dispatcher. Motion then
  /// becomes a fade or an instant change; haptics stay.
  static bool reduceMotionOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
}
