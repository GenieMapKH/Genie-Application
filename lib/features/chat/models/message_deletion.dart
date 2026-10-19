/// A message was deleted for this user: by them (on any device), or by the
/// sender for everyone. Nothing is shown in its place.
class MessageDeletion {
  final String messageId;

  /// The other person in the conversation it belonged to.
  final String participantId;

  const MessageDeletion({required this.messageId, required this.participantId});

  factory MessageDeletion.fromJson(Map<String, dynamic> json) {
    return MessageDeletion(
      messageId: json['messageId'] as String,
      participantId: json['participantId'] as String,
    );
  }
}
