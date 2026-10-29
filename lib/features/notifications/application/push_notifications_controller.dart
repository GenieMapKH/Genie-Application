import 'dart:async';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/notifications/data/push_messaging.dart';
import 'package:tilomnov/features/notifications/data/system_notifications.dart';
import 'package:tilomnov/features/notifications/models/push_message.dart';

/// Opens what a tapped notification is about. Supplied by the app, which
/// knows every screen.
typedef PushOpener = Future<void> Function(PushMessage message);

/// Whether a push that arrives while the app is open is worth showing:
/// not, for instance, a message in the conversation already on screen.
typedef ForegroundPushFilter = bool Function(PushMessage message);

/// Receives a call push while the app is open (the call feature rings).
typedef CallPushHandler = void Function(PushMessage message);

/// Writes the notification of a chat message that came with its sealed text
/// (Android): the sender's name, and what it says if this phone can read it.
/// Supplied by the app, which joins chat and notifications.
typedef ChatPushText =
    Future<({String title, String body})> Function(ChatMessagePush message);

/// What happens to a push once it reaches the app: shown when it arrives
/// while the app is open (the system shows only those that arrive while it
/// is not), and opened when the user taps one.
class PushNotificationsController {
  final PushMessaging messaging;
  final SystemNotifications system;
  final PushOpener open;
  final ForegroundPushFilter shouldShow;
  final CallPushHandler? onCallPush;
  final ChatPushText? chatText;

  final _subscriptions = <StreamSubscription<void>>[];

  PushNotificationsController({
    required this.messaging,
    required this.system,
    required this.open,
    required this.shouldShow,
    this.onCallPush,
    this.chatText,
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

    // Android gets the sealed message and no notification: write it here.
    if (message is ChatMessagePush && message.isSealed && push.title == null) {
      unawaited(_showSealedMessage(message, push.data));
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
      ListingAlertPush(:final propertyId) => (
        NotificationChannel.listingAlerts,
        'listing:$propertyId',
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

  Future<void> _showSealedMessage(
    ChatMessagePush message,
    Map<String, dynamic> data,
  ) async {
    final write = chatText;
    if (write == null || !shouldShow(message)) return;
    try {
      final text = await write(message);
      await system.show(
        title: text.title,
        body: text.body,
        channel: NotificationChannel.chatMessages,
        // The notification carries no sealed text once shown.
        data: ChatMessagePush.withoutSealedText(data),
        tag: 'chat:${message.senderId}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Notification not shown', e, stackTrace);
    }
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
