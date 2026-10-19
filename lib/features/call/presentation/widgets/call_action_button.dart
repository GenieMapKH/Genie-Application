import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';

/// A round call button with its label underneath: answer, end, mute...
/// The circle and the label are one target, so it is easy to hit.
class CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// A filled colour (answer green, end red); otherwise a quiet circle.
  final Color? background;

  /// A switch that is on (muted, loudspeaker) is filled in.
  final bool selected;

  const CallActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled =
        background ?? (selected ? colors.textPrimary : colors.surface);
    final foreground = background != null
        ? Colors.white
        : (selected ? colors.background : colors.textPrimary);

    return Semantics(
      button: true,
      toggled: background == null ? selected : null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ink(
                width: 68,
                height: 68,
                decoration: ShapeDecoration(
                  color: filled,
                  shape: CircleBorder(
                    side: background == null
                        ? BorderSide(color: colors.border)
                        : BorderSide.none,
                  ),
                ),
                child: Icon(icon, size: 30, color: foreground),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
