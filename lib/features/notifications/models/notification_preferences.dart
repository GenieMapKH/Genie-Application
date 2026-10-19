/// What the user chose to be told about. Security alerts and calls always
/// arrive, so they are not here.
class NotificationPreferences {
  final bool chatMessages;
  final bool promotions;

  const NotificationPreferences({
    required this.chatMessages,
    required this.promotions,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      chatMessages: json['chatMessages'] != false,
      promotions: json['promotions'] != false,
    );
  }

  NotificationPreferences copyWith({bool? chatMessages, bool? promotions}) {
    return NotificationPreferences(
      chatMessages: chatMessages ?? this.chatMessages,
      promotions: promotions ?? this.promotions,
    );
  }
}
