import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/features/chat/models/chat_composer_mode.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_message_action_problem_text.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_message_actions_sheet.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_message_bubble.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_message_time_text.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/delete_message_dialog.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/swipe_to_reply.dart';
import 'package:tilomnov/features/chat/providers/active_chat_provider.dart';
import 'package:tilomnov/features/chat/providers/chat_composer_provider.dart';
import 'package:tilomnov/features/chat/providers/chat_tapped_message_provider.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// One message with what can be done to it: swipe it to reply (the other
/// person's to the right, the user's own to the left), hold it for reply,
/// copy, edit and delete, or tap it to see when it was sent and, for the
/// user's own, delivered.
class ChatMessageTile extends ConsumerWidget {
  static const _revealDuration = Duration(milliseconds: 150);

  final ChatParticipants chat;
  final ChatMessage message;
  final String participantName;

  /// Says "Sent" below the message: the user's newest one in the chat.
  final bool showSentStatus;

  const ChatMessageTile({
    super.key,
    required this.chat,
    required this.message,
    required this.participantName,
    this.showSentStatus = false,
  });

  bool get _isMine => message.senderId == chat.userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tapped = ref.watch(
      chatTappedMessageProvider(chat).select((id) => id == message.id),
    );
    final locale = Localizations.localeOf(context).toLanguageTag();
    final status = _statusText(context, locale, tapped: tapped);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: _revealDuration,
          alignment: Alignment.topCenter,
          child: tapped
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    chatMessageTimeText(
                      context.l10n,
                      locale,
                      message.createdAt,
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textMuted,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        _buildMessage(context, ref),
        AnimatedSize(
          duration: _revealDuration,
          alignment: Alignment.topCenter,
          child: status == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    status,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textHint,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// "Sent", or once tapped, when it was delivered. Only for the user's own
  /// stored messages: the bubble itself says when one is sending or failed.
  String? _statusText(
    BuildContext context,
    String locale, {
    required bool tapped,
  }) {
    if (!_isMine || message.status != ChatMessageStatus.sent) return null;
    if (tapped) {
      return chatDeliveredText(context.l10n, locale, message.createdAt);
    }
    return showSentStatus ? context.l10n.chatMessageSent : null;
  }

  void _toggleDetails(WidgetRef ref) {
    final tapped = ref.read(chatTappedMessageProvider(chat).notifier);
    tapped.state = tapped.state == message.id ? null : message.id;
  }

  Widget _buildMessage(BuildContext context, WidgetRef ref) {
    final quoted = message.replyTo;
    return SwipeToReply(
      towardsLeft: _isMine,
      onReply: message.canReply
          ? () => _compose(ref, ReplyingTo(message))
          : null,
      child: GestureDetector(
        onTap: () => _toggleDetails(ref),
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
