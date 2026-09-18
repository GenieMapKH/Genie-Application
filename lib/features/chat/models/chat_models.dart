class ChatConversation {
  final String id;
  final String participantName;
  final String participantId;
  final String? participantAvatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.participantId,
    this.participantAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final lastMsg = json['lastMessage'];
    final createdAtStr = lastMsg != null ? lastMsg['createdAt'] : null;
    String formattedTime = '';
    if (createdAtStr != null) {
      final dt = DateTime.tryParse(createdAtStr)?.toLocal();
      if (dt != null) {
        final now = DateTime.now();
        if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
          formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          formattedTime = '${dt.month}/${dt.day}';
        }
      }
    }

    return ChatConversation(
      id: json['participantId'] ?? '',
      participantName: json['participantName'] ?? 'Property Owner',
      participantId: json['participantId'] ?? '',
      participantAvatar: json['participantAvatar'],
      lastMessage: lastMsg != null ? (lastMsg['ciphertext'] != null ? 'Message' : '') : '',
      lastMessageTime: formattedTime,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  ChatConversation copyWith({
    String? id,
    String? participantName,
    String? participantId,
    String? participantAvatar,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      participantId: participantId ?? this.participantId,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

