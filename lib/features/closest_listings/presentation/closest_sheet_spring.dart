import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'package:tilomnov/core/theme/app_motion.dart';

/// Moves the map's pull-up list to a stop on a spring, starting at the
/// speed it already has: let go of, a slow pull glides on slowly and a
/// flick carries its momentum. (The sheet's own release let a fling run
/// out, then started a separate move to the stop, stalling between the
/// two.)
class ClosestSheetSpring {
  final DraggableScrollableController sheet;
  final AnimationController _spring;

  ClosestSheetSpring({required TickerProvider vsync, required this.sheet})
    : _spring = AnimationController.unbounded(vsync: vsync) {
    _spring.addListener(_follow);
  }

  /// Whether the spring, not a finger, is moving the sheet.
  bool get isMoving => _moving;
  bool _moving = false;

  /// Counts moves, so the end of one replaced by the next is ignored.
  int _move = 0;
  double _target = 0;

  /// Moves the sheet to [extent], at first at [velocity] (extents a
  /// second, upwards positive). Without [animate] it is there at once.
  void moveTo(double extent, {double velocity = 0, bool animate = true}) {
    if (!sheet.isAttached) return;
    final move = ++_move;
    _target = extent;
    _moving = true;
    // Stops the sheet's own fling, if one runs.
    sheet.jumpTo(sheet.size);
    if (!animate) return _land(move);

    _spring.value = sheet.size;
    _spring
        .animateWith(
          SpringSimulation(AppMotion.smooth, sheet.size, extent, velocity),
        )
        .whenCompleteOrCancel(() => _land(move));
  }

  /// A finger took hold: the sheet stays where it is, under it.
  void stop() {
    _move++;
    _moving = false;
    _spring.stop();
  }

  void _follow() {
    if (!sheet.isAttached) return stop();
    sheet.jumpTo(_spring.value.clamp(0.0, 1.0));
  }

  void _land(int move) {
    if (move != _move) return;
    // The spring ends within a hair of its stop; it rests exactly on it.
    if (sheet.isAttached) sheet.jumpTo(_target);
    _moving = false;
  }

  void dispose() => _spring.dispose();
}
