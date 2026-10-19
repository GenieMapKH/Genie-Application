import 'dart:async';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/notifications/data/push_messaging.dart';
import 'package:genie/features/notifications/data/system_notifications.dart';
import 'package:genie/features/notifications/models/push_message.dart';

/// Opens what a tapped notification is about. Supplied by the app, which
/// knows every screen.
typedef PushOpener = Future<void> Function(PushMessage message);

/// Whether a push that arrives while the app is open is worth showing:
/// not, for instance, a message in the conversation already on screen.
typedef ForegroundPushFilter = bool Function(PushMessage message);

/// Receives a call push while the app is open (the call feature rings).
typedef CallPushHandler = void Function(PushMessage message);

/// What happens to a push once it reaches the app: shown when it arrives
/// while the app is open (the system shows only those that arrive while it
/// is not), and opened when the user taps one.
class PushNotificationsController {
  final PushMessaging messaging;
  final SystemNotifications system;
  final PushOpener open;
  final ForegroundPushFilter shouldShow;
  final CallPushHandler? onCallPush;

  final _subscriptions = <StreamSubscription<void>>[];

  PushNotificationsController({
    required this.messaging,
    required this.system,
    required this.open,
    required this.shouldShow,
    this.onCallPush,
  });

  Future<void> start() async {
    await system.initialize(_openData);
    _subscriptions
      ..add(messaging.foregroundPushes.listen(_onForeground))
      ..add(messaging.openedPushes.listen((push) => _openData(push.data)));

    // The app was started by tapping a notification.
    final launch = await messaging.launchPush();
    final data = launch?.data ?? await system.launchData();
    if (data != null) _openData(data);
  }

  void _onForeground(ReceivedPush push) {
    final message = PushMessage.fromData(push.data);
    if (message is IncomingCallPush || message is CallEndedPush) {
      onCallPush?.call(message);
      return;
    }

    final title = push.title;
    if (title == null || !shouldShow(message)) return;
    final (channel, tag) = switch (message) {
      ChatMessagePush(:final senderId) => (
        NotificationChannel.chatMessages,
        'chat:$senderId',
      ),
      SignInAlertPush() => (NotificationChannel.security, null),
      PromotionPush(:final promotionId) => (
        NotificationChannel.promotions,
        'promotion:$promotionId',
      ),
      _ => (NotificationChannel.chatMessages, null),
    };
    system
        .show(
          title: title,
          body: push.body ?? '',
          channel: channel,
          data: push.data,
          tag: tag,
        )
        .catchError((Object e, StackTrace stackTrace) {
          AppLogger.error('Notification not shown', e, stackTrace);
        });
  }

  void _openData(Map<String, dynamic> data) {
    open(PushMessage.fromData(data)).catchError((
      Object e,
      StackTrace stackTrace,
    ) {
      AppLogger.error('Notification could not be opened', e, stackTrace);
    });
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}
