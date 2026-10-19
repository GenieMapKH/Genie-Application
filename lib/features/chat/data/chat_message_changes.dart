import 'package:dio/dio.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/models/chat_message_action_problem.dart';
import 'package:genie/features/chat/models/chat_models.dart';

/// What came of an edit: when the server says it was edited, or why not.
typedef ChatEditResult = ({
  DateTime? editedAt,
  ChatMessageActionProblem? problem,
});

/// Sends edits and deletes of single messages to the server. An edit is
/// sealed again here, so the server still never sees the text.
class ChatMessageChanges {
  final MessageCipher cipher;
  final ChatRepository repository;

  const ChatMessageChanges({required this.cipher, required this.repository});

  /// Replaces the text of the user's own [message] with [text].
  Future<ChatEditResult> edit(
    ChatMessage message,
    String text, {
    required String peerId,
  }) async {
    try {
      final sealed = await cipher.encrypt(
        text,
        id: message.id,
        peerId: peerId,
        replyToId: message.replyToId,
      );
      final stored = await repository.editMessage(
        message.id,
        ciphertext: sealed.ciphertext,
        nonce: sealed.nonce,
      );
      return (editedAt: stored.editedAt ?? DateTime.now(), problem: null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to edit a message', e, stackTrace);
      final tooLate = e is DioException && e.response?.statusCode == 403;
      return (
        editedAt: null,
        problem: tooLate
            ? ChatMessageActionProblem.editTooLate
            : ChatMessageActionProblem.failed,
      );
    }
  }

  /// Deletes [message] for the user, or with [forEveryone] for both people.
  /// One the server no longer has counts as deleted.
  Future<ChatMessageActionProblem?> delete(
    ChatMessage message, {
    required bool forEveryone,
  }) async {
    try {
      await repository.deleteMessage(
        message.id,
        forEveryone: forEveryone,
        attachmentPath: message.attachment?.path,
      );
      return null;
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == 404) return null;
      AppLogger.error('Failed to delete a message', e, stackTrace);
      return ChatMessageActionProblem.failed;
    }
  }
}
