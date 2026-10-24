import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_reply.dart';

/// Turns stored messages into readable ones, each with the message it
/// replies to.
class ChatMessageReader {
  final MessageCipher cipher;

  const ChatMessageReader(this.cipher);

  /// A message this device cannot open is kept, with a placeholder text.
  Future<ChatMessage> read(EncryptedMessage encrypted) async {
    final opened = await cipher.decrypt(encrypted);
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

  /// Only the message the sender sealed into their reply is quoted: the
  /// server can leave a quote out (the message was deleted), never swap it.
  Future<ChatReplyPreview?> _quoted(
    EncryptedMessage? quoted, {
    required String? sealedId,
  }) async {
    if (quoted == null || sealedId == null || quoted.id != sealedId) {
      return null;
    }
    final opened = await cipher.decrypt(quoted);
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
