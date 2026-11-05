import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:tilomnov/features/notifications/data/system_notifications.dart';

/// Rings on Android when the app is not open: a full-screen notification
/// that keeps ringing until it is answered, declined or the call ends.
/// Used from the background push handler, where only plugins exist.
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
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
  }) {
    return plugin.show(
      id: _firebaseId,
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
          ongoing: true,
          autoCancel: false,
          timeoutAfter: _ringFor.inMilliseconds,
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
      plugin.cancel(id: _firebaseId, tag: tagOf(callId));

  /// Takes the ringing notification's place. The server's own "Missed call"
  /// usually got there first (same tag), so this one makes no sound.

  Future<void> showMissed({
    required String callId,
    required String title,
    required Map<String, dynamic> data,
  }) {
    return plugin.show(
      id: _firebaseId,
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

  /// One notification per call, the one the server's pushes also name: the
  /// ringing one replaces the system's "is calling", the missed one replaces
  /// the ringing one.
  static String tagOf(String callId) => 'call:$callId';

  /// Firebase shows a tagged push with id 0 (see
  /// `LocalSystemNotifications.notificationIdOf`).
  static const _firebaseId = 0;
}
