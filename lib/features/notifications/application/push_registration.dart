import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/notifications/data/notification_repository.dart';
import 'package:genie/features/notifications/data/push_messaging.dart';

/// Keeps the server told where this device can be reached, for the account
/// signed in on it, and in which language to write to it.
class PushRegistration {
  final PushMessaging messaging;
  final NotificationRepository repository;

  /// Which kind of device this is; null where pushes are not used (desktop).
  final PushPlatform? platform;

  String? _token;
  String _locale = 'en';
  StreamSubscription<String>? _refreshes;

  PushRegistration({
    required this.messaging,
    required this.repository,
    required this.platform,
  });

  /// What this device is, as the server names it.
  static PushPlatform? get currentPlatform {
    if (kIsWeb) return PushPlatform.web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => PushPlatform.android,
      TargetPlatform.iOS => PushPlatform.ios,
      _ => null,
    };
  }

  /// Asks for permission (once: the system remembers the answer), then
  /// registers. False when the user said no or this device cannot get pushes.
  Future<bool> start({required String locale}) async {
    _locale = locale;
    final platform = this.platform;
    if (platform == null) return false;
    if (!await messaging.requestPermission()) return false;

    final token = await messaging.token();
    if (token == null) return false;
    await _register(token);

    // Firebase replaces a token now and then; the server must follow.
    _refreshes ??= messaging.tokenRefreshes.listen((token) {
      _register(token).catchError((Object e, StackTrace stackTrace) {
        AppLogger.error('New push token not registered', e, stackTrace);
      });
    });
    return true;
  }

  /// Stops this device receiving the account's pushes: before signing out,
  /// while the session is still valid. Never throws; the server also drops
  /// the device when the session ends.
  Future<void> stop() async {
    await _refreshes?.cancel();
    _refreshes = null;
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await repository.removeDevice(token);
    } catch (e, stackTrace) {
      AppLogger.error('Push device not removed', e, stackTrace);
    }
    try {
      // A new token is made for whoever signs in next.
      await messaging.deleteToken();
    } catch (e, stackTrace) {
      AppLogger.error('Push token not deleted', e, stackTrace);
    }
  }

  Future<void> _register(String token) async {
    await repository.registerDevice(
      token: token,
      platform: platform!,
      locale: _locale,
    );
    _token = token;
  }

  void dispose() {
    _refreshes?.cancel();
  }
}
