import 'package:tilomnov/features/chat/data/message_codec.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';

/// The text of each conversation's last message, decrypted for the list.
/// Previews already opened are kept by message id and payload (an edit changes
/// its content), so reloading the list opens only what is new.
class ConversationPreviews {
  final MessageCodec cipher;

  final _previews = <String, String>{};
  static const _maxPreviews = 500;

  ConversationPreviews(this.cipher);

  /// [conversation] showing its last message's text, or as it is when that
  /// cannot be decrypted.
  Future<ChatConversation> shown(ChatConversation conversation) async {
    final lastMessage = conversation.lastMessageFor(cipher.userId);
    if (lastMessage == null) return conversation;

    final known = _previews[_key(lastMessage.id, lastMessage.ciphertext)];
    if (known != null) return conversation.copyWith(lastMessage: known);

    final opened = await cipher.decode(lastMessage);
    if (opened == null) return conversation;
    final preview = ChatConversation.previewOf(opened.text, opened.attachment);
    remember(lastMessage.id, lastMessage.ciphertext, preview);
    return conversation.copyWith(lastMessage: preview);
  }

  /// Keeps [preview] as the text of message [messageId] sealed with
  /// [content]. Only what decrypted is kept: a failure may succeed later.
  void remember(String messageId, String content, String preview) {
    final key = _key(messageId, content);
    _previews.remove(key);
    _previews[key] = preview;
    if (_previews.length > _maxPreviews) _previews.remove(_previews.keys.first);
  }

  static String _key(String messageId, String content) => '$messageId:$content';
}
