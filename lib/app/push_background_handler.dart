import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tilomnov/app/push_chat_text.dart';
import 'package:tilomnov/features/call/data/call_notifications.dart';
import 'package:tilomnov/features/chat/e2ee/keys/crypto_service.dart';
import 'package:tilomnov/features/chat/e2ee/push_preview.dart';
import 'package:tilomnov/features/notifications/data/system_notifications.dart';
import 'package:tilomnov/features/notifications/models/push_message.dart';
import 'package:tilomnov/features/settings/data/app_settings_storage.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// Runs when a push arrives while the app is closed or in the background
/// (a separate isolate, without the app's state). Pushes with a visible
/// notification are shown by the system; only Android's silent pushes are
/// handled here: a call (ring, stop ringing, tell of a missed call) and a
/// chat message sent with its sealed text (open it, show it).
@pragma('vm:entry-point')
Future<void> handleBackgroundPush(RemoteMessage message) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final push = PushMessage.fromData(message.data);
  if (push is ChatMessagePush) {
    // One with a notification of its own was already shown by the system.
    if (push.isSealed && message.notification == null) {
      await _showChatMessage(push, message.data);
    }
    return;
  }
  if (push is! IncomingCallPush && push is! CallEndedPush) return;

  WidgetsFlutterBinding.ensureInitialized();
  final l10n = await _appLanguage();
  final calls = CallNotifications();
  await calls.initialize();

  switch (push) {
    case IncomingCallPush(:final callId, :final callerName, :final sentAt):
      // A push held back while the phone was off is about a call long over.
      if (sentAt != null &&
          DateTime.now().difference(sentAt) > const Duration(seconds: 45)) {
        return;
      }
      await calls.showIncoming(
        callId: callId,
        title: l10n.callIncomingFrom(callerName),
        acceptLabel: l10n.callAccept,
        declineLabel: l10n.callDecline,
        data: message.data,
      );
    case CallEndedPush(:final callId, :final callerName, :final missed):
      await calls.cancel(callId);
      if (missed) {
        await calls.showMissed(
          callId: callId,
          title: l10n.callMissedFrom(callerName),
          data: message.data,
        );
      }
    default:
      break;
  }
}

/// Libsodium starts once per isolate.
Future<CryptoService>? _crypto;

/// Shows a chat message that came with its sealed text, opened with the keys
/// on this phone. Where it cannot be opened, or the user turned the text off,
/// the notification says only that a message arrived.
Future<void> _showChatMessage(
  ChatMessagePush push,
  Map<String, dynamic> data,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  final l10n = await _appLanguage();
  final preferences = await SharedPreferences.getInstance();
  // This isolate may have been kept since an earlier push.
  await preferences.reload();

  final text = await chatNotificationText(
    push: push,
    l10n: l10n,
    showText: AppSettingsStorage(preferences).readShowNotificationText(),
    previewFor: (userId) async => ChatPushPreview.forAccount(
      userId,
      await (_crypto ??= CryptoService.init()),
    ),
  );

  final notifications = LocalSystemNotifications();
  // Taps are handled by the app once it opens.
  await notifications.initialize((_) {});
  await notifications.show(
    title: text.title,
    body: text.body,
    channel: NotificationChannel.chatMessages,
    // The notification carries no sealed text once shown.
    data: ChatMessagePush.withoutSealedText(data),
    tag: 'chat:${push.senderId}',
  );
}

/// The language the user picked in the app, else the phone's.
Future<AppLocalizations> _appLanguage() async {
  final saved = AppSettingsStorage(
    await SharedPreferences.getInstance(),
  ).readLocale();
  final code =
      saved?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(code == 'km' ? 'km' : 'en'));
}
