import 'package:tilomnov/features/chat/models/chat_models.dart';

/// How a conversation's messages change when one of them is edited or
/// deleted: replies that quote it change with it.
extension ChatMessageList on List<ChatMessage> {
  /// The message with [text], and every reply quoting it too.
  List<ChatMessage> withEdit(
    String messageId,
    String text,
    DateTime editedAt,
  ) => [
    for (final message in this)
      if (message.id == messageId)
        message.copyWith(text: text, editedAt: editedAt)
      else if (message.replyTo case final quoted?
          when quoted.messageId == messageId)
        message.copyWith(replyTo: quoted.withText(text))
      else
        message,
  ];

  /// Without the message, and without its quote in replies: nothing of it
  /// is left.
  List<ChatMessage> without(String messageId) => [
    for (final message in this)
      if (message.id != messageId)
        message.replyTo?.messageId == messageId
            ? message.copyWith(withoutReply: true)
            : message,
  ];
}
