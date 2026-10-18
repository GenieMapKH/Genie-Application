/// A conversation was archived, restored or deleted, on this device, another
/// of the user's devices, or (deleted for everyone) by the other person.
class ConversationChange {
  final String participantId;

  /// Its messages were deleted: an open chat must drop what it shows.
  final bool historyCleared;

  const ConversationChange({
    required this.participantId,
    required this.historyCleared,
  });

  factory ConversationChange.fromJson(Map<String, dynamic> json) {
    return ConversationChange(
      participantId: json['participantId'] as String,
      historyCleared: json['historyCleared'] == true,
    );
  }
}
