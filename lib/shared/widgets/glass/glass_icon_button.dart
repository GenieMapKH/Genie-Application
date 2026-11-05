import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/shared/widgets/buttons/tactile_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_surface.dart';

/// A round glass button floating over a page: the back, call and share
/// buttons of headers and photo galleries while `GlassScope` is on.
class GlassIconButton extends StatelessWidget {
  final IconData icon;

  /// Null draws it dimmed and ignores taps.
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Defaults to the theme's text colour, readable on its glass.
  final Color? color;
  final double size;
  final double iconSize;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 40,
    this.iconSize = 22,
  }) : _isBack = false;

  /// The back button: a chevron, as iOS draws it, named for screen readers.
  const GlassIconButton.back({super.key, required this.onPressed})
    : icon = Icons.arrow_back_ios_new_rounded,
      tooltip = null,
      color = null,
      size = 40,
      iconSize = 18,
      _isBack = true;

  /// Made by [GlassIconButton.back]: named by the platform's "Back".
  final bool _isBack;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final tooltip =
        this.tooltip ??
        (_isBack ? MaterialLocalizations.of(context).backButtonTooltip : null);
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      excludeSemantics: tooltip != null,
      child: TactileButton(
        pressedScale: 0.9,
        onPressed: onPressed,
        child: GlassCircle(
          size: size,
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Icon(
              icon,
              size: iconSize,
              color: color ?? context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip, excludeFromSemantics: true, child: button);
  }
}

/// A round pane of glass [size] across, [child] in its middle: the face of
/// [GlassIconButton], and of buttons that bring their own tap handling (a
/// menu button).
class GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;

  const GlassCircle({super.key, this.size = 40, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: child),
      ),
    );
  }
}
