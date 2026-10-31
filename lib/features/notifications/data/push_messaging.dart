import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:tilomnov/core/config/app_config.dart';

/// A push as it reaches the app: its data, and what the system showed.
typedef ReceivedPush = ({
  Map<String, dynamic> data,
  String? title,
  String? body,
});

/// How this device receives pushes. An interface so the rest of the app can
/// be tested without Firebase.
abstract interface class PushMessaging {
  /// Asks the user, where the system asks (Android 13+, iOS, browsers).
  Future<bool> requestPermission();

  /// Whether the user allows notifications for this app right now.
  Future<bool> isAllowed();

  /// The address of this device, or null where pushes cannot work.
  Future<String?> token();

  Stream<String> get tokenRefreshes;

  /// Pushes that arrive while the app is on screen. The system shows none.
  Stream<ReceivedPush> get foregroundPushes;

  /// Pushes the user tapped while the app was in the background.
  Stream<ReceivedPush> get openedPushes;

  /// The push the user tapped to start the app, if any.
  Future<ReceivedPush?> launchPush();

  /// Forgets this device's address, so nothing reaches it any more.
  Future<void> deleteToken();
}

/// [PushMessaging] with Firebase Cloud Messaging.
class FirebasePushMessaging implements PushMessaging {
  final FirebaseMessaging _messaging;

  FirebasePushMessaging([FirebaseMessaging? messaging])
    : _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return _allows(settings);
  }

  @override
  Future<bool> isAllowed() async =>
      _allows(await _messaging.getNotificationSettings());

  @override
  Future<String?> token() async {
    if (kIsWeb) {
      // A browser needs the project's web push key (public, from the env file).
      if (!AppConfig.hasWebPushKey || !await _messaging.isSupported()) {
        return null;
      }
      return _messaging.getToken(vapidKey: AppConfig.webPushKey);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        !await _waitForApnsToken()) {
      return null;
    }
    return _messaging.getToken();
  }

  /// On iOS, getToken throws until Apple has answered the app's registration,
  /// which arrives a moment after permission is granted. A device Apple never
  /// answers (most simulators, a build without the push entitlement) gives up.
  Future<bool> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (await _messaging.getAPNSToken() != null) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<ReceivedPush> get foregroundPushes =>
      FirebaseMessaging.onMessage.map(_received);

  @override
  Stream<ReceivedPush> get openedPushes =>
      FirebaseMessaging.onMessageOpenedApp.map(_received);

  @override
  Future<ReceivedPush?> launchPush() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _received(message);
  }

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  static bool _allows(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  static ReceivedPush _received(RemoteMessage message) => (
    data: message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );
}
