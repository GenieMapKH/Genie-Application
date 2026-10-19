import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/app/push_chat_text.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/e2ee/push_preview.dart';
import 'package:genie/features/notifications/models/push_message.dart';
import 'package:genie/l10n/generated/app_localizations.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final khmer = lookupAppLocalizations(const Locale('km'));

  const sealed = ChatMessagePush(
    senderId: 'alice',
    senderName: 'Alice',
    messageId: 'm1',
    recipientId: 'bob',
    ciphertext: 'sealed',
    nonce: 'n',
  );

  late List<String> openedFor;

  /// A phone whose keys open the message as [opened] (null: they do not).
  Future<ChatPushPreview> Function(String) phone(OpenedMessage? opened) =>
      (userId) async {
        openedFor.add(userId);
        return ChatPushPreview(open: (_) async => opened);
      };

  setUp(() => openedFor = []);

  test('says what the message says, under the sender\'s name', () async {
    final text = await chatNotificationText(
      push: sealed,
      l10n: english,
      showText: true,
      previewFor: phone((id: 'm1', text: 'see you at 5', attachment: null)),
    );

    expect(text, (title: 'Alice', body: 'see you at 5'));
    expect(openedFor, ['bob']);
  });

  test(
    'says only that a message arrived when the user turned text off',
    () async {
      final text = await chatNotificationText(
        push: sealed,
        l10n: english,
        showText: false,
        previewFor: phone((id: 'm1', text: 'secret', attachment: null)),
      );

      expect(text, (title: 'Alice', body: 'New message'));
      // Not even opened: the text is never read when it is not going to be shown.
      expect(openedFor, isEmpty);
    },
  );

  test(
    'says only that a message arrived when this phone cannot open it',
    () async {
      final text = await chatNotificationText(
        push: sealed,
        l10n: english,
        showText: true,
        previewFor: phone(null),
      );

      expect(text, (title: 'Alice', body: 'New message'));
    },
  );

  test('survives the keys being unreadable', () async {
    final text = await chatNotificationText(
      push: sealed,
      l10n: english,
      showText: true,
      previewFor: (_) async => throw Exception('secure storage unavailable'),
    );

    expect(text, (title: 'Alice', body: 'New message'));
  });

  test('is generic for a push without a sealed message', () async {
    const plain = ChatMessagePush(
      senderId: 'alice',
      senderName: 'Alice',
      messageId: 'm1',
    );

    final text = await chatNotificationText(
      push: plain,
      l10n: english,
      showText: true,
      previewFor: phone((id: 'm1', text: 'never used', attachment: null)),
    );

    expect(text.body, 'New message');
    expect(openedFor, isEmpty);
  });

  test(
    'falls back to wording of its own when the sender has no name',
    () async {
      const unnamed = ChatMessagePush(
        senderId: 'alice',
        senderName: '',
        messageId: 'm1',
        recipientId: 'bob',
        ciphertext: 'sealed',
        nonce: 'n',
      );

      final text = await chatNotificationText(
        push: unnamed,
        l10n: english,
        showText: false,
        previewFor: phone(null),
      );

      expect(text.title, 'New message');
    },
  );

  test('is written in the user\'s language', () async {
    final text = await chatNotificationText(
      push: sealed,
      l10n: khmer,
      showText: false,
      previewFor: phone(null),
    );

    expect(text.body, khmer.chatPreviewNewMessage);
    expect(text.body, isNot('New message'));
  });
}
