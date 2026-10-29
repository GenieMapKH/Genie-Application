import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:tilomnov/core/device/app_haptics.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/core/theme/app_motion.dart';

/// The heart on a listing card. Saving makes it jump and spring back with a
/// light tap felt in the hand; unsaving gives only a small dip, as removing
/// something is not worth celebrating.
class FavoriteHeartButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onPressed;
  final double iconSize;

  /// The heart's colour while the listing is not saved.
  final Color? idleColor;

  const FavoriteHeartButton({
    super.key,
    required this.isFavorite,
    this.onPressed,
    this.iconSize = 19,
    this.idleColor,
  });

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  /// Unbounded so the spring can carry the heart past its size and back.
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant FavoriteHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Changed elsewhere (another card, the detail sheet): still answer it,
    // unless this button's own tap already did.
    if (oldWidget.isFavorite != widget.isFavorite && !_scale.isAnimating) {
      _react(saved: widget.isFavorite);
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _react({required bool saved}) {
    if (AppMotion.reduceMotionOf(context)) return;
    _scale.animateWith(
      saved
          ? SpringSimulation(AppMotion.bouncy, 0.7, 1, 0)
          : SpringSimulation(AppMotion.snappy, 0.88, 1, 0),
    );
  }

  void _handleTap() {
    final saving = !widget.isFavorite;
    if (saving) AppHaptics.lightTap();
    _react(saved: saving);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      toggled: widget.isFavorite,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.fade,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey<bool>(widget.isFavorite),
                  size: widget.iconSize,
                  color: widget.isFavorite
                      ? colors.accent
                      : widget.idleColor ?? colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
