/// What the user chose to be told about. Security alerts and calls always
/// arrive, so they are not here.
class NotificationPreferences {
  final bool chatMessages;
  final bool promotions;

  /// New listings matching one of their saved searches.
  final bool savedSearchAlerts;

  /// New listings from people they follow.
  final bool followedListings;

  /// Price drops and sales of listings they saved.
  final bool savedListingUpdates;

  const NotificationPreferences({
    required this.chatMessages,
    required this.promotions,
    this.savedSearchAlerts = true,
    this.followedListings = true,
    this.savedListingUpdates = true,
  });

  /// A switch an older server does not send is on, as the server starts it.
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      chatMessages: json['chatMessages'] != false,
      promotions: json['promotions'] != false,
      savedSearchAlerts: json['savedSearchAlerts'] != false,
      followedListings: json['followedListings'] != false,
      savedListingUpdates: json['savedListingUpdates'] != false,
    );
  }

  NotificationPreferences copyWith({
    bool? chatMessages,
    bool? promotions,
    bool? savedSearchAlerts,
    bool? followedListings,
    bool? savedListingUpdates,
  }) {
    return NotificationPreferences(
      chatMessages: chatMessages ?? this.chatMessages,
      promotions: promotions ?? this.promotions,
      savedSearchAlerts: savedSearchAlerts ?? this.savedSearchAlerts,
      followedListings: followedListings ?? this.followedListings,
      savedListingUpdates: savedListingUpdates ?? this.savedListingUpdates,
    );
  }
}
