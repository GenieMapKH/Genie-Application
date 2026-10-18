import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// A centred message in place of the conversation: why chat cannot show
/// here, and the one thing to do about it.
class ChatNotice extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;

  /// Red instead of the brand colour, for a lock that holds for a while.
  final bool isWarning;
  final VoidCallback? onAction;

  /// The button's label; "Try again" when null.
  final String? actionLabel;

  /// Small print under the button, e.g. where to go after a forgotten PIN.
  final String? footnote;

  const ChatNotice({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.isWarning = false,
    this.onAction,
    this.actionLabel,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = this.icon;
    final title = this.title;
    final footnote = this.footnote;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              CircleAvatar(
                radius: 32,
                backgroundColor: isWarning
                    ? colors.dangerSoft
                    : colors.primarySoft,
                child: Icon(
                  icon,
                  size: 30,
                  color: isWarning ? colors.danger : colors.primary,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (title != null) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colors.textMuted,
                height: 1.5,
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel ?? context.l10n.chatTryAgain),
              ),
            ],
            if (footnote != null) ...[
              const SizedBox(height: 16),
              Text(
                footnote,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.4,
                  color: colors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
