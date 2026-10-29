/// How a call in the conversation went, from the point of view of the person
/// looking at it.
enum ChatCallOutcome {
  /// Answered and then hung up by either person.
  completed,

  /// Answered, then the connection was lost.
  lost,

  /// This person called; nobody answered.
  noAnswer,

  /// This person called and hung up before it was answered.
  cancelled,

  /// This person called; the other person turned it down.
  declinedByPeer,

  /// The other person called; this person turned it down.
  declinedByMe,

  /// The other person called; this person did not pick up.
  missed,
}

/// One finished call with the other person of a conversation, as the server
/// lists it (`GET /chat/calls/history`). Shown among the messages.
class ChatCallEntry {
  final String id;
  final String callerId;

  /// When it started ringing.
  final DateTime createdAt;

  /// Null when it was never answered.
  final DateTime? answeredAt;
  final DateTime? endedAt;

  /// 'ended', 'declined', 'missed', 'cancelled' or 'disconnected'.
  final String? endReason;

  const ChatCallEntry({
    required this.id,
    required this.callerId,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
    this.endReason,
  });

  factory ChatCallEntry.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) {
      final text = json[key];
      return text is String ? DateTime.tryParse(text) : null;
    }

    return ChatCallEntry(
      id: json['id'] as String,
      callerId: json['callerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      answeredAt: time('answeredAt'),
      endedAt: time('endedAt'),
      endReason: json['endReason'] as String?,
    );
  }

  /// How long the two people talked; null when it was never answered.
  Duration? get talkTime {
    final answered = answeredAt;
    final ended = endedAt;
    if (answered == null || ended == null || ended.isBefore(answered)) {
      return null;
    }
    return ended.difference(answered);
  }

  ChatCallOutcome outcomeFor(String userId) {
    final iCalled = callerId == userId;
    if (answeredAt != null) {
      return endReason == 'disconnected'
          ? ChatCallOutcome.lost
          : ChatCallOutcome.completed;
    }
    return switch (endReason) {
      'declined' =>
        iCalled ? ChatCallOutcome.declinedByPeer : ChatCallOutcome.declinedByMe,
      'missed' => iCalled ? ChatCallOutcome.noAnswer : ChatCallOutcome.missed,
      // Hung up, or the caller's connection dropped, before it was answered.
      _ => iCalled ? ChatCallOutcome.cancelled : ChatCallOutcome.missed,
    };
  }
}
