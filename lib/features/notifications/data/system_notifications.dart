import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:genie/core/logging/app_logger.dart';

/// A kind of notification with its own switch in the phone's settings
/// (an Android channel). The server names the same ids in its pushes.
enum NotificationChannel {
  chatMessages('chat_messages', 'Chat messages', Importance.high),
  security('security', 'Security alerts', Importance.high),
  promotions('promotions', 'Offers and news', Importance.defaultImportance),
  listingAlerts(
    'listing_alerts',
    'New listings for you',
    Importance.defaultImportance,
  ),
  calls('calls', 'Calls', Importance.max),
  missedCalls('missed_calls', 'Missed calls', Importance.high);

  final String id;
  final String label;
  final Importance importance;

  const NotificationChannel(this.id, this.label, this.importance);

  /// The ringtone, for an incoming call (a channel's sound is fixed once
  /// it exists).
  static const _ringtone = UriAndroidNotificationSound(
    'content://settings/system/ringtone',
  );

  /// How Android creates this channel.
  AndroidNotificationChannel get android => AndroidNotificationChannel(
    id,
    label,
    importance: importance,
    sound: this == calls ? _ringtone : null,
    audioAttributesUsage: this == calls
        ? AudioAttributesUsage.notificationRingtone
        : AudioAttributesUsage.notification,
  );

  /// Creates every channel. Safe to repeat; Android keeps the first.
  static Future<void> createAll(FlutterLocalNotificationsPlugin plugin) async {
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    for (final channel in values) {
      await android.createNotificationChannel(channel.android);
    }
  }

  static NotificationChannel byId(String? id) => values.firstWhere(
    (channel) => channel.id == id,
    orElse: () => NotificationChannel.chatMessages,
  );
}

/// Notifications this app shows itself: a push that arrives while the app
/// is open (the system shows only those that arrive while it is not).
abstract interface class SystemNotifications {
  /// Prepares the channels; [onTap] receives the data of a tapped one.
  Future<void> initialize(void Function(Map<String, dynamic> data) onTap);

  /// Shows a notification. One with the same [tag] replaces it.
  Future<void> show({
    required String title,
    required String body,
    required NotificationChannel channel,
    required Map<String, dynamic> data,
    String? tag,
  });

  /// The data of the notification tapped to start the app, if any.
  Future<Map<String, dynamic>?> launchData();
}

/// [SystemNotifications] with flutter_local_notifications. Only phones and
/// browsers show them; elsewhere (desktop development) nothing is shown.
class LocalSystemNotifications implements SystemNotifications {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  LocalSystemNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static bool get _supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> initialize(
    void Function(Map<String, dynamic> data) onTap,
  ) async {
    if (!_supported) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        // The logo's house in white (android/.../drawable-*/ic_stat_notification):
        // Android draws a small icon as a flat shape, so the full-colour
        // launcher icon would show as a blob.
        android: AndroidInitializationSettings('ic_stat_notification'),
        // Permission is asked with Firebase, at sign-in, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final data = withAction(response.payload, response.actionId);
        if (data != null) onTap(data);
      },
    );
    await NotificationChannel.createAll(_plugin);
    _ready = true;
  }

  @override
  Future<void> show({
    required String title,
    required String body,
    required NotificationChannel channel,
    required Map<String, dynamic> data,
    String? tag,
  }) async {
    if (!_ready) return;
    await _plugin.show(
      // The same tag gets the same id, so a newer one replaces it.
      id:
          (tag ?? '${DateTime.now().microsecondsSinceEpoch}').hashCode &
          0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.label,
          importance: channel.importance,
          priority: Priority.high,
          tag: tag,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: tag),
      ),
      payload: jsonEncode(data),
    );
  }

  @override
  Future<Map<String, dynamic>?> launchData() async {
    if (!_supported || kIsWeb) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final response = details.notificationResponse;
    return withAction(response?.payload, response?.actionId);
  }

  /// A tapped notification's data, with the button tapped (e.g. "accept")
  /// as `action`.
  static Map<String, dynamic>? withAction(String? payload, String? actionId) {
    final data = _decode(payload);
    if (data != null && actionId != null && actionId.isNotEmpty) {
      data['action'] = actionId;
    }
    return data;
  }

  static Map<String, dynamic>? _decode(String? payload) {
    if (payload == null) return null;
    try {
      final data = jsonDecode(payload);
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } on FormatException catch (e) {
      AppLogger.error('Ignored a notification with unreadable data', e);
      return null;
    }
  }
}
