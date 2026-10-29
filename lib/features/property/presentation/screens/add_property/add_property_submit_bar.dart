import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tilomnov/core/theme/app_colors.dart';

/// The buttons pinned under the add-property form, side by side. Slides away
/// while the keyboard is open so it never covers the field being typed in.
class AddPropertySubmitBar extends StatelessWidget {
  final List<Widget> children;

  const AddPropertySubmitBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnimatedSlide(
      offset: isKeyboardOpen ? const Offset(0, 1.2) : Offset.zero,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutQuad,
      child: AnimatedOpacity(
        opacity: isKeyboardOpen ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutQuad,
        child: IgnorePointer(
          ignoring: isKeyboardOpen,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
              bottom: 70.0,
            ),
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One button of an [AddPropertySubmitBar]: filled for the main action,
/// outlined for the secondary one. Shows a spinner in place of its icon
/// while [isLoading], and is disabled while [onPressed] is null.
class AddPropertySubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool filled;
  final VoidCallback? onPressed;

  const AddPropertySubmitButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = filled ? colors.onPrimary : colors.accent;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    );
    final leading = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: foreground, strokeWidth: 2),
          )
        : Icon(icon, color: foreground, size: 20);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: foreground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    if (!filled) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: leading,
        label: text,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          side: BorderSide(color: colors.accent, width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: shape,
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: leading,
      label: text,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent,
        disabledBackgroundColor: colors.accent.withValues(alpha: 0.6),
        minimumSize: const Size(double.infinity, 50),
        shape: shape,
        elevation: 4,
      ),
    );
  }
}
