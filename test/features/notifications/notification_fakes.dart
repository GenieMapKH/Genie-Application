import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/notifications/data/notification_repository.dart';
import 'package:tilomnov/features/notifications/data/push_messaging.dart';
import 'package:tilomnov/features/notifications/data/system_notifications.dart';
import 'package:tilomnov/features/notifications/models/notification_preferences.dart';

class FakePushMessaging implements PushMessaging {
  bool allow = true;
  String? currentToken = 'token-1';
  ReceivedPush? launch;
  int deletedTokens = 0;
  final refreshes = StreamController<String>.broadcast();
  final foreground = StreamController<ReceivedPush>.broadcast();
  final opened = StreamController<ReceivedPush>.broadcast();

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<bool> isAllowed() async => allow;

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  @override
  Stream<ReceivedPush> get foregroundPushes => foreground.stream;

  @override
  Stream<ReceivedPush> get openedPushes => opened.stream;

  @override
  Future<ReceivedPush?> launchPush() async => launch;

  @override
  Future<void> deleteToken() async => deletedTokens++;
}

/// One notification shown by the app.
typedef ShownNotification = ({
  String title,
  String body,
  NotificationChannel channel,
  String? tag,
});

class FakeSystemNotifications implements SystemNotifications {
  final shown = <ShownNotification>[];

  /// The data each shown notification carries, for when it is tapped.
  final shownData = <Map<String, dynamic>>[];
  void Function(Map<String, dynamic> data)? tap;
  Map<String, dynamic>? launch;

  @override
  Future<void> initialize(
    void Function(Map<String, dynamic> data) onTap,
  ) async => tap = onTap;

  @override
  Future<void> show({
    required String title,
    required String body,
    required NotificationChannel channel,
    required Map<String, dynamic> data,
    String? tag,
  }) async {
    shown.add((title: title, body: body, channel: channel, tag: tag));
    shownData.add(data);
  }

  @override
  Future<Map<String, dynamic>?> launchData() async => launch;
}

class FakeNotificationRepository extends Fake
    implements NotificationRepository {
  final registered = <({String token, PushPlatform platform, String locale})>[];
  final removed = <String>[];
  NotificationPreferences preferences = const NotificationPreferences(
    chatMessages: true,
    promotions: true,
  );
  Object? error;

  @override
  Future<void> registerDevice({
    required String token,
    required PushPlatform platform,
    required String locale,
  }) async {
    if (error != null) throw error!;
    registered.add((token: token, platform: platform, locale: locale));
  }

  @override
  Future<void> removeDevice(String token) async {
    if (error != null) throw error!;
    removed.add(token);
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    if (error != null) throw error!;
    return preferences;
  }

  @override
  Future<NotificationPreferences> updatePreferences({
    bool? chatMessages,
    bool? promotions,
    bool? savedSearchAlerts,
    bool? followedListings,
    bool? savedListingUpdates,
  }) async {
    if (error != null) throw error!;
    return preferences = preferences.copyWith(
      chatMessages: chatMessages,
      promotions: promotions,
      savedSearchAlerts: savedSearchAlerts,
      followedListings: followedListings,
      savedListingUpdates: savedListingUpdates,
    );
  }
}
