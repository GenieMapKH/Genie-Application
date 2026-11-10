import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:tilomnov/features/notifications/data/system_notifications.dart';

/// Rings on Android when the app is not open: a full-screen notification
/// that keeps ringing until it is answered, declined or the call ends.
/// Also used for socket invitations while the app is running in the background.
///
/// Accept opens the app and answers. Decline only silences this phone: the
/// caller hears "no answer" when the server stops the ring.
class CallNotifications {
  static const acceptAction = 'accept';
  static const declineAction = 'decline';

  /// Android's FLAG_INSISTENT: the sound repeats until the notification goes.
  static const _keepRinging = 4;

  /// The server stops ringing after 45 seconds.
  static const _ringFor = Duration(seconds: 45);

  final FlutterLocalNotificationsPlugin plugin;

  CallNotifications([FlutterLocalNotificationsPlugin? plugin])
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Prepares the plugin in a background isolate.
  Future<void> initialize() async {
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
      ),
    );
    await NotificationChannel.createAll(plugin);
  }

  Future<void> showIncoming({
    required String callId,
    required String title,
    required String acceptLabel,
    required String declineLabel,
    required Map<String, dynamic> data,
  }) async {
    final sentAt = switch (data['sentAt']) {
      String value => DateTime.tryParse(value),
      _ => null,
    };
    final remaining = sentAt == null
        ? _ringFor
        : _ringFor - DateTime.now().difference(sentAt);
    if (remaining <= Duration.zero) return;
    return plugin.show(
      id: idOf(callId),
      title: title,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannel.calls.id,
          NotificationChannel.calls.label,
          tag: tagOf(callId),
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
          onlyAlertOnce: true,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          timeoutAfter: remaining.inMilliseconds.clamp(
            1,
            _ringFor.inMilliseconds,
          ),
          audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
          additionalFlags: Int32List.fromList([_keepRinging]),
          actions: [
            AndroidNotificationAction(declineAction, declineLabel),
            AndroidNotificationAction(
              acceptAction,
              acceptLabel,
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  /// The call stopped ringing (answered elsewhere, or declined).
  Future<void> cancel(String callId) =>
      plugin.cancel(id: idOf(callId), tag: tagOf(callId));

  /// Android 14+ opens the system's special-access page when needed.
  Future<void> requestFullScreenPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestFullScreenIntentPermission();
  }

  /// Takes the ringing notification's place without repeating its alert.
  Future<void> showMissed({
    required String callId,
    required String title,
    required Map<String, dynamic> data,
  }) {
    return plugin.show(
      id: idOf(callId),
      title: title,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannel.missedCalls.id,
          NotificationChannel.missedCalls.label,
          tag: tagOf(callId),
          onlyAlertOnce: true,
          importance: NotificationChannel.missedCalls.importance,
          category: AndroidNotificationCategory.missedCall,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  /// One notification per call; a missed call replaces its ringing notification.
  static String tagOf(String callId) => 'call:$callId';

  /// Stable across processes. A separate PendingIntent keeps chat pushes from
  /// overwriting a call's tap/Accept payload (Android ignores extras for identity).
  static int idOf(String callId) {
    var id = 0;
    for (final code in callId.codeUnits) {
      id = (id * 31 + code) & 0x7fffffff;
    }
    return id == 0 ? 1 : id;
  }
}
