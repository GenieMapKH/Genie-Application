import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/presentation/widgets/chat_conversation_tile.dart';
import 'package:genie/features/chat/presentation/widgets/delete_chat_dialog.dart';
import 'package:genie/features/chat/providers/conversation_actions.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/swipe_action_tile.dart';

/// A conversation in the chat list or the archive: tap to open it; swipe it
/// left or long-press it to archive (or move back) and delete it.
class ChatListEntry extends ConsumerWidget {
  final ChatConversation chat;

  /// Shown in the archive: offers "move back" instead of "archive".
  final bool isArchived;

  const ChatListEntry({
    super.key,
    required this.chat,
    required this.isArchived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwipeActionTile(
      actions: [
        SwipeAction(
          icon: isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
          label: isArchived ? l10n.chatUnarchive : l10n.chatArchive,
          color: context.colors.accent,
          onPressed: () => _toggleArchive(context, ref),
        ),
        SwipeAction(
          icon: Icons.delete_outline,
          label: l10n.chatDelete,
          color: context.colors.danger,
          onPressed: () => _delete(context, ref),
        ),
      ],
      child: ChatConversationTile(
        chat: chat,
        onTap: () => _open(context),
        onLongPress: () => _showMenu(context, ref),
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatConversationPage(
          participantId: chat.participantId,
          participantName: chat.participantName,
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<_MenuChoice>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              ),
              title: Text(
                isArchived ? l10n.chatUnarchiveChat : l10n.chatArchiveChat,
              ),
              onTap: () => Navigator.of(sheetContext).pop(_MenuChoice.archive),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.colors.danger),
              title: Text(
                l10n.chatDeleteChat,
                style: TextStyle(color: context.colors.danger),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_MenuChoice.delete),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _MenuChoice.archive:
        await _toggleArchive(context, ref);
      case _MenuChoice.delete:
        await _delete(context, ref);
    }
  }

  Future<void> _toggleArchive(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(conversationActionsProvider);
    final id = chat.participantId;

    final done = await _attempt(
      messenger,
      l10n.chatActionFailed,
      () => isArchived ? actions.unarchive(id) : actions.archive(id),
    );
    if (!done) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isArchived ? l10n.chatUnarchivedDone : l10n.chatArchivedDone,
        ),
        action: SnackBarAction(
          label: l10n.chatUndo,
          onPressed: () => _attempt(
            messenger,
            l10n.chatActionFailed,
            () => isArchived ? actions.archive(id) : actions.unarchive(id),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(conversationActionsProvider);

    final forEveryone = await DeleteChatDialog.show(
      context,
      chat.participantName,
    );
    if (forEveryone == null) return;

    final done = await _attempt(
      messenger,
      l10n.chatActionFailed,
      () => actions.delete(
        chat.participantId,
        forEveryone: forEveryone,
        fromArchive: isArchived,
      ),
    );
    if (done) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatDeletedDone)));
    }
  }

  /// Runs [action]; on failure logs it and tells the user. True on success.
  static Future<bool> _attempt(
    ScaffoldMessengerState messenger,
    String failureMessage,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Chat list action failed', e, stackTrace);
      messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
      return false;
    }
  }
}

enum _MenuChoice { archive, delete }
