import 'package:tilomnov/features/chat/models/chat_attachment.dart';

/// The message a reply quotes, as shown above the reply. It is the quoted
/// message as it is now: an edit changes it, and a delete removes it.
class ChatReplyPreview {
  final String messageId;
  final String senderId;

  /// Empty for a picture, voice message or file without text.
  final String text;
  final ChatAttachment? attachment;

  const ChatReplyPreview({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.attachment,
  });

  /// The quoted message after its sender edited it.
  ChatReplyPreview withText(String text) => ChatReplyPreview(
    messageId: messageId,
    senderId: senderId,
    text: text,
    attachment: attachment,
  );
}
