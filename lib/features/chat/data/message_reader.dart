import 'package:tilomnov/features/chat/data/message_codec.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_reply.dart';

/// Turns stored messages into readable ones, each with the message it
/// replies to.
class ChatMessageReader {
  final MessageCodec cipher;

  const ChatMessageReader(this.cipher);

  /// A message this device cannot open is kept, with a placeholder text.
  Future<ChatMessage> read(EncryptedMessage encrypted) async {
    final opened = await cipher.decode(encrypted);
    return ChatMessage(
      id: opened?.id ?? encrypted.id,
      senderId: encrypted.senderId,
      recipientId: encrypted.recipientId,
      text: opened?.text ?? ChatMessage.undecryptableText,
      createdAt: encrypted.createdAt,
      attachment: opened?.attachment,
      listing: opened?.listing,
      editedAt: encrypted.editedAt,
      replyToId: opened?.replyToId,
      replyTo: await _quoted(encrypted.replyTo, sealedId: opened?.replyToId),
    );
  }

  /// Shows only the quoted message identified by this reply's envelope.
  Future<ChatReplyPreview?> _quoted(
    EncryptedMessage? quoted, {
    required String? sealedId,
  }) async {
    if (quoted == null || sealedId == null || quoted.id != sealedId) {
      return null;
    }
    final opened = await cipher.decode(quoted);
    if (opened != null && opened.id != null && opened.id != quoted.id) {
      return null;
    }
    return ChatReplyPreview(
      messageId: quoted.id,
      senderId: quoted.senderId,
      text: opened?.text ?? ChatMessage.undecryptableText,
      attachment: opened?.attachment,
    );
  }
}
