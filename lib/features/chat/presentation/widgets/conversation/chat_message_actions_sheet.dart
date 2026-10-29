import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// What the user chose to do with a message they held down.
enum ChatMessageAction { reply, copy, edit, delete }

/// The actions for one message, offered after holding it down. Only those
/// that apply are listed: copy needs text, edit is for the user's own text
/// message in its first hour, and a message still sending has none.
Future<ChatMessageAction?> showChatMessageActions(
  BuildContext context, {
  required ChatMessage message,
  required String userId,
}) {
  final actions = [
    if (message.canReply) ChatMessageAction.reply,
    if (message.hasText) ChatMessageAction.copy,
    if (message.canBeEditedBy(userId, DateTime.now())) ChatMessageAction.edit,
    if (message.status != ChatMessageStatus.sending) ChatMessageAction.delete,
  ];
  if (actions.isEmpty) return Future.value();

  return showModalBottomSheet<ChatMessageAction>(
    context: context,
    backgroundColor: context.colors.surface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final action in actions) _ActionTile(action)],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final ChatMessageAction action;

  const _ActionTile(this.action);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDelete = action == ChatMessageAction.delete;
    final color = isDelete ? context.colors.danger : context.colors.textPrimary;
    final (icon, label) = switch (action) {
      ChatMessageAction.reply => (Icons.reply, l10n.chatReply),
      ChatMessageAction.copy => (Icons.copy_outlined, l10n.chatCopy),
      ChatMessageAction.edit => (Icons.edit_outlined, l10n.chatEdit),
      ChatMessageAction.delete => (Icons.delete_outline, l10n.chatDelete),
    };

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.inter(fontSize: 15, color: color)),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}
