import 'package:genie/features/chat/models/chat_models.dart';

/// What the message bar does with the next text, besides sending a new
/// message: reply to [message], or replace its text.
sealed class ChatComposerMode {
  final ChatMessage message;

  const ChatComposerMode(this.message);
}

/// The next message quotes [message].
final class ReplyingTo extends ChatComposerMode {
  const ReplyingTo(super.message);
}

/// The next text replaces the text of [message], the user's own.
final class EditingMessage extends ChatComposerMode {
  const EditingMessage(super.message);
}
