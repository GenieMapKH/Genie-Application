import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/e2ee/keys/message_cipher.dart';
import 'package:tilomnov/features/chat/e2ee/push_preview.dart';
import 'package:tilomnov/features/chat/models/chat_attachment.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';

import 'chat_fakes.dart';
import 'voice_fakes.dart';

const _labels = (photo: 'Photo', voice: 'Voice message');

void main() {
  EncryptedMessage? seen;

  Future<String?> bodyOf(
    OpenedMessage? opened, {
    String ciphertext = 'sealed',
  }) {
    seen = null;
    final preview = ChatPushPreview(
      open: (message) async {
        seen = message;
        return opened;
      },
    );
    return preview.bodyOf(
      senderId: peer,
      recipientId: me,
      messageId: 'm1',
      ciphertext: ciphertext,
      nonce: 'n',
      labels: _labels,
    );
  }

  OpenedMessage message(String text, [ChatAttachment? attachment]) => (
    id: 'm1',
    text: text,
    attachment: attachment,
    replyToId: null,
    listing: null,
  );

  group('the words of a notification', () {
    test('are what the message says', () async {
      expect(await bodyOf(message('see you at 5')), 'see you at 5');
    });

    test('hand the sealed message to be opened as it arrived', () async {
      await bodyOf(message('hi'));

      expect(seen!.id, 'm1');
      expect(seen!.senderId, peer);
      expect(seen!.recipientId, me);
      expect(seen!.ciphertext, 'sealed');
      expect(seen!.nonce, 'n');
    });

    test('name a picture, a voice message or a file by what it is', () async {
      expect(await bodyOf(message('', fakeAttachment(1))), '\u{1F4F7} Photo');
      expect(
        await bodyOf(message('', voiceAttachment(2))),
        '\u{1F3A4} Voice message',
      );
      expect(
        await bodyOf(
          message(
            '',
            fakeAttachment(3, name: 'lease.pdf', mimeType: 'application/pdf'),
          ),
        ),
        '\u{1F4CE} lease.pdf',
      );
    });

    test('keep a picture\'s caption beside it', () async {
      expect(
        await bodyOf(message('the front yard', fakeAttachment(1))),
        '\u{1F4F7} Photo  the front yard',
      );
    });

    test('are nothing when the phone cannot open the message', () async {
      expect(await bodyOf(null), isNull);
    });

    test('are nothing for a message with no text and no file', () async {
      expect(await bodyOf(message('   ')), isNull);
    });

    test('are cut when the message is long', () async {
      final body = await bodyOf(message('word ' * 200));

      expect(body!.length, ChatPushPreview.maxLength);
      expect(body, endsWith('…'));
    });
  });
}
