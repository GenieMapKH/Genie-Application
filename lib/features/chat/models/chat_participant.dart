/// Whether the other person is connected to chat right now.
class ChatPresence {
  final String userId;
  final bool online;

  /// When they were last connected. Null while online, or if never seen.
  final DateTime? lastSeenAt;

  const ChatPresence({
    required this.userId,
    required this.online,
    this.lastSeenAt,
  });

  factory ChatPresence.fromJson(Map<String, dynamic> json) {
    final lastSeenAt = json['lastSeenAt'] as String?;
    return ChatPresence(
      userId: json['userId'] as String,
      online: json['online'] == true,
      lastSeenAt: lastSeenAt == null ? null : DateTime.parse(lastSeenAt),
    );
  }
}

/// What a user may see about the person they are chatting with.
class ChatParticipantProfile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final DateTime memberSince;

  const ChatParticipantProfile({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.memberSince,
  });

  factory ChatParticipantProfile.fromJson(Map<String, dynamic> json) {
    return ChatParticipantProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      memberSince: DateTime.parse(json['createdAt'] as String),
    );
  }
}
