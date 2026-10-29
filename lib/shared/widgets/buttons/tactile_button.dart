import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:tilomnov/core/theme/app_motion.dart';

/// A button that answers a touch the way iOS controls do: it sinks the moment
/// a finger lands, stays down while held, and springs back when released,
/// carrying on from wherever it was rather than restarting a timed animation.
/// With reduced motion it dims instead of moving.
class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  /// How far the button shrinks while held.
  final double pressedScale;

  const TactileButton({
    super.key,
    required this.child,
    this.onPressed,
    this.pressedScale = 0.96,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton>
    with SingleTickerProviderStateMixin {
  static const _pressedOpacity = 0.6;

  /// How far the button is pressed in: 0 at rest, 1 fully down. Unbounded so
  /// the release spring may overshoot a little past rest.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduceMotionOf(context);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _springTo(double target, SpringDescription spring) {
    _press.animateWith(
      SpringSimulation(spring, _press.value, target, _press.velocity),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    _springTo(1, AppMotion.press);
  }

  void _release() => _springTo(0, AppMotion.snappy);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final shrink = 1 - widget.pressedScale;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: _handleTapDown,
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _press,
            child: widget.child,
            builder: (context, child) {
              final pressed = _press.value;
              if (_reduceMotion) {
                return Opacity(
                  opacity: (1 - pressed * (1 - _pressedOpacity)).clamp(0, 1),
                  child: child,
                );
              }
              return Transform.scale(scale: 1 - pressed * shrink, child: child);
            },
          ),
        ),
      ),
    );
  }
}
