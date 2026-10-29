import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// Who a message is deleted for.
enum MessageDeletionScope { me, everyone }

/// Asks before deleting a message. The user's own message can be deleted
/// for everyone or only for them; the other person's only for the user.
/// Null when the user cancels.
Future<MessageDeletionScope?> showDeleteMessageDialog(
  BuildContext context, {
  required bool isMine,
  required String participantName,
}) {
  return showDialog<MessageDeletionScope>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      Widget choice(MessageDeletionScope scope, String label) => TextButton(
        onPressed: () => Navigator.of(context).pop(scope),
        style: TextButton.styleFrom(foregroundColor: context.colors.danger),
        child: Text(label),
      );

      return AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          l10n.chatDeleteMessageQuestion,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isMine
              ? l10n.chatDeleteOwnMessageExplained(participantName)
              : l10n.chatDeleteMessageForMeExplained(participantName),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: context.colors.textMuted,
          ),
        ),
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          choice(MessageDeletionScope.me, l10n.chatDeleteMessageForMe),
          if (isMine)
            choice(
              MessageDeletionScope.everyone,
              l10n.chatDeleteMessageForEveryone,
            ),
        ],
      );
    },
  );
}
