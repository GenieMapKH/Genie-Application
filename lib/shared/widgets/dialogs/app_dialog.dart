import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// What a dialog is about; sets the colour of its icon badge and main button.
enum AppDialogTone { neutral, danger }

/// The app's one dialog: a rounded card with an icon badge, a centred title
/// and message, optional [content] and a main button over a quiet one.
///
/// Use [show] so every dialog opens the same way. Pop with a value to answer
/// it; the buttons here pop `true` (main) and `false` (secondary) unless they
/// have their own handler.
class AppDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? content;
  final AppDialogTone tone;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryBusy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.content,
    this.tone = AppDialogTone.neutral,
    required this.primaryLabel,
    this.onPrimary,
    this.primaryBusy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, _) => SafeArea(
        // Lifts the card above the keyboard while a note is typed.
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: MediaQuery.viewInsetsOf(dialogContext),
          child: Center(child: builder(dialogContext)),
        ),
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final danger = tone == AppDialogTone.danger;
    final badge = danger ? colors.danger : colors.accent;
    final secondary = secondaryLabel;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: badge.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: badge, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: content)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: primaryBusy
                  ? null
                  : onPrimary ?? () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: danger ? colors.danger : colors.accent,
                foregroundColor: colors.onPrimary,
                disabledBackgroundColor:
                    (danger ? colors.danger : colors.accent).withValues(
                      alpha: 0.5,
                    ),
                disabledForegroundColor: colors.onPrimary,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: primaryBusy
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Text(
                      primaryLabel,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            if (secondary != null) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed:
                    onSecondary ?? () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: colors.textMuted,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(
                  secondaryLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
