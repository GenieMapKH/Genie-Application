import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/chat/models/chat_composer_mode.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_message_action_problem_text.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_message_actions_sheet.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_message_bubble.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/delete_message_dialog.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/swipe_to_reply.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/chat/providers/chat_composer_provider.dart';
import 'package:genie/l10n/l10n.dart';

/// One message with what can be done to it: swipe it to reply (the other
/// person's to the right, the user's own to the left), or hold it for
/// reply, copy, edit and delete.
class ChatMessageTile extends ConsumerWidget {
  final ChatParticipants chat;
  final ChatMessage message;
  final String participantName;

  const ChatMessageTile({
    super.key,
    required this.chat,
    required this.message,
    required this.participantName,
  });

  bool get _isMine => message.senderId == chat.userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoted = message.replyTo;
    return SwipeToReply(
      towardsLeft: _isMine,
      onReply: message.canReply
          ? () => _compose(ref, ReplyingTo(message))
          : null,
      child: GestureDetector(
        onLongPress: () => _showActions(context, ref),
        child: ChatMessageBubble(
          message: message,
          isMine: _isMine,
          onRetry: () =>
              ref.read(activeChatProvider(chat).notifier).retry(message.id),
          quotedAuthorName: quoted == null
              ? ''
              : quoted.senderId == chat.userId
              ? context.l10n.chatYou
              : participantName,
        ),
      ),
    );
  }

  void _compose(WidgetRef ref, ChatComposerMode mode) {
    ref.read(chatComposerProvider(chat).notifier).state = mode;
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final action = await showChatMessageActions(
      context,
      message: message,
      userId: chat.userId,
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case ChatMessageAction.reply:
        _compose(ref, ReplyingTo(message));
      case ChatMessageAction.edit:
        _compose(ref, EditingMessage(message));
      case ChatMessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.chatCopied)));
      case ChatMessageAction.delete:
        await _delete(context, ref);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final scope = await showDeleteMessageDialog(
      context,
      // A message that never reached the server has no one else to delete it for.
      isMine: _isMine && message.status == ChatMessageStatus.sent,
      participantName: participantName,
    );
    if (scope == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final problem = await ref
        .read(activeChatProvider(chat).notifier)
        .deleteMessage(
          message.id,
          forEveryone: scope == MessageDeletionScope.everyone,
        );
    if (problem == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(chatMessageActionProblemText(l10n, problem))),
      );
  }
}
