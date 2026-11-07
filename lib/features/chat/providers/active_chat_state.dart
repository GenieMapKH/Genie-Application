import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_send_problem.dart';

enum ActiveChatStatus { loading, ready, unavailable }

/// Who is talking to whom: the key of an open conversation.
typedef ChatParticipants = ({String userId, String participantId});

/// The conversation currently on screen.
class ActiveChatState {
  final ActiveChatStatus status;

  /// Oldest first.
  final List<ChatMessage> messages;

  /// Why the last message could not be sent. The screen says it.
  final ChatSendProblem? sendError;

  const ActiveChatState({
    this.status = ActiveChatStatus.loading,
    this.messages = const [],
    this.sendError,
  });

  /// [sendError] is cleared unless it is passed again.
  ActiveChatState copyWith({
    ActiveChatStatus? status,
    List<ChatMessage>? messages,
    ChatSendProblem? sendError,
  }) {
    return ActiveChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      sendError: sendError,
    );
  }
}
