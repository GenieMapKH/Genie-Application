import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// Asks before deleting a chat with [participantName], with a tick box to
/// delete it for them too. Returns whether to delete it for both people, or
/// null when the user cancels.
class DeleteChatDialog extends StatefulWidget {
  final String participantName;

  const DeleteChatDialog({super.key, required this.participantName});

  static Future<bool?> show(BuildContext context, String participantName) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteChatDialog(participantName: participantName),
    );
  }

  @override
  State<DeleteChatDialog> createState() => _DeleteChatDialogState();
}

class _DeleteChatDialogState extends State<DeleteChatDialog> {
  bool _forEveryone = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = widget.participantName;

    return AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(
        l10n.chatDeleteChatQuestion,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _forEveryone
                ? l10n.chatDeleteForBothExplained
                : l10n.chatDeleteForMeExplained(name),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _forEveryone
                  ? context.colors.danger
                  : context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _forEveryone,
            onChanged: (value) => setState(() => _forEveryone = value ?? false),
            title: Text(
              l10n.chatDeleteForBoth(name),
              style: GoogleFonts.inter(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_forEveryone),
          style: TextButton.styleFrom(foregroundColor: context.colors.danger),
          child: Text(l10n.chatDelete),
        ),
      ],
    );
  }
}
