class ChatConversation {
  final String id;
  final String participantName;
  final String participantId;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.participantId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
}

// Temporary empty list until we build local database sync
final List<ChatConversation> mockConversations = [];
