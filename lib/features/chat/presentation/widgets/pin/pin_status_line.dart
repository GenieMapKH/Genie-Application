import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';
import 'package:genie/l10n/l10n.dart';

/// The line under a PIN field: "Checking...", or what went wrong with the
/// last PIN (tries left, the wait after too many, no connection). Keeps its
/// height when empty, so the field does not jump.
class PinStatusLine extends StatelessWidget {
  final bool checking;
  final PinCheckResult? result;

  /// How long the lock after too many wrong PINs still lasts, if known.
  final Duration? lockLeft;

  /// A problem found before anything was sent, e.g. PINs that do not match.
  final String? errorText;

  /// Shown while [checking]; "Checking your PIN..." when null.
  final String? checkingText;

  const PinStatusLine({
    super.key,
    this.checking = false,
    this.result,
    this.lockLeft,
    this.errorText,
    this.checkingText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = checking ? null : errorText ?? _describe(context.l10n);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 20),
      child: checking
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  checkingText ?? context.l10n.pinChecking,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                ),
              ],
            )
          : message == null
          ? const SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 18, color: colors.danger),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: colors.danger,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String? _describe(AppLocalizations l10n) {
    return switch (result) {
      PinRejected(attemptsLeft: final left?) => l10n.pinWrongTriesLeft(left),
      PinRejected() => l10n.pinWrongNoCount,
      PinLockedOut() => _lockedMessage(l10n),
      PinCheckFailed() => l10n.pinCheckFailed,
      PinAccepted() || null => null,
    };
  }

  String _lockedMessage(AppLocalizations l10n) {
    final left = lockLeft;
    if (left == null) return l10n.pinLockedLater;
    return l10n.pinLockedFor(formatWait(left));
  }
}

/// "14:05", or "1:02:09" for an hour or more: how long a lock still lasts.
String formatWait(Duration wait) {
  final seconds = (wait.inSeconds % 60).toString().padLeft(2, '0');
  final minutes = wait.inMinutes % 60;
  if (wait.inHours == 0) return '$minutes:$seconds';
  return '${wait.inHours}:${minutes.toString().padLeft(2, '0')}:$seconds';
}
