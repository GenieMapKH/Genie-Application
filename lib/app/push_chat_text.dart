import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/e2ee/push_preview.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/features/notifications/application/push_notifications_controller.dart';
import 'package:tilomnov/features/notifications/models/push_message.dart';
import 'package:tilomnov/features/notifications/providers/notification_providers.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// What the app shows for a chat message: the sender's name, and the text
/// when this phone can read it (and the user allows it), else "New message".
///
/// Lives in `app/` because it joins chat (which opens the message) and
/// notifications (which show it). Used both while the app is open and by the
/// background push handler, which has no providers: it passes [previewFor].
Future<({String title, String body})> chatNotificationText({
  required ChatMessagePush push,
  required AppLocalizations l10n,
  required bool showText,
  required Future<ChatPushPreview> Function(String userId) previewFor,
}) async {
  final title = push.senderName.isEmpty
      ? l10n.chatPreviewNewMessage
      : push.senderName;
  var body = l10n.chatPreviewNewMessage;

  if (showText && push.isSealed) {
    try {
      final preview = await previewFor(push.recipientId!);
      final text = await preview.bodyOf(
        senderId: push.senderId,
        recipientId: push.recipientId!,
        messageId: push.messageId!,
        ciphertext: push.ciphertext!,
        nonce: push.nonce!,
        labels: (photo: l10n.chatPreviewPhoto, voice: l10n.chatPreviewVoice),
      );
      if (text != null) body = text;
    } catch (e, stackTrace) {
      // The notification still says who wrote.
      AppLogger.error('A message in a push could not be opened', e, stackTrace);
    }
  }
  return (title: title, body: body);
}

/// Writes the notification of a chat message that arrives while the app is
/// open, with the keys the app already holds.
ChatPushText chatPushText(Ref ref) {
  return (push) => chatNotificationText(
    push: push,
    l10n: lookupAppLocalizations(Locale(ref.read(pushLocaleProvider))),
    showText: ref.read(showNotificationTextProvider),
    previewFor: (userId) async {
      final cipher = ref.read(messageCipherProvider(userId));
      return ChatPushPreview(
        open: (message) => cipher.decrypt(message, askServer: false),
      );
    },
  );
}
