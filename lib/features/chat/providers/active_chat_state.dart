import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/models/chat_models.dart';

enum ActiveChatStatus { loading, ready, unavailable }

/// Who is talking to whom: the key of an open conversation.
typedef ChatParticipants = ({String userId, String participantId});

/// The conversation currently on screen.
class ActiveChatState {
  final ActiveChatStatus status;

  /// Why the chat could not be opened, when [status] is unavailable.
  final E2eeSetupResult? setupResult;

  /// Oldest first.
  final List<ChatMessage> messages;

  /// The server lists a different key for the other person than the one
  /// this device trusts. Nothing is sent until the user accepts the new key.
  final bool peerKeyChanged;

  /// Why the last message could not be sent, for the user to read.
  final String? sendError;

  const ActiveChatState({
    this.status = ActiveChatStatus.loading,
    this.setupResult,
    this.messages = const [],
    this.peerKeyChanged = false,
    this.sendError,
  });

  /// [sendError] is cleared unless it is passed again.
  ActiveChatState copyWith({
    ActiveChatStatus? status,
    List<ChatMessage>? messages,
    bool? peerKeyChanged,
    String? sendError,
  }) {
    return ActiveChatState(
      status: status ?? this.status,
      setupResult: setupResult,
      messages: messages ?? this.messages,
      peerKeyChanged: peerKeyChanged ?? this.peerKeyChanged,
      sendError: sendError,
    );
  }
}
