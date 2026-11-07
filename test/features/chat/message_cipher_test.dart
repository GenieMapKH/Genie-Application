import 'package:tilomnov/features/chat/providers/conversation_previews.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/data/message_codec.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_listing.dart';

void main() {
  const alice = MessageCodec(userId: 'alice');
  const bob = MessageCodec(userId: 'bob');
  EncryptedMessage delivered(
    ({String ciphertext, String nonce}) body, {
    String id = 'm1',
    String recipient = 'bob',
  }) => EncryptedMessage(
    id: id,
    senderId: 'alice',
    recipientId: recipient,
    ciphertext: body.ciphertext,
    nonce: body.nonce,
    createdAt: DateTime.utc(2026),
  );
  test(
    'new messages work on either account without device keys or PINs',
    () async {
      final body = await alice.encode(
        'Hello សួស្ដី',
        id: 'm1',
        peerId: 'bob',
        replyToId: 'quoted',
      );
      expect(body.nonce, 'managed-v1');
      expect((await bob.decode(delivered(body)))?.text, 'Hello សួស្ដី');
      expect((await alice.decode(delivered(body)))?.replyToId, 'quoted');
    },
  );
  test('older encrypted history remains inaccessible', () async {
    expect(
      await bob.decode(
        delivered((ciphertext: 'old-ciphertext', nonce: 'old-nonce')),
      ),
      isNull,
    );
  });
  test(
    'rejects another conversation, a relabeled id, and malformed content',
    () async {
      final body = await alice.encode('hello', id: 'm1', peerId: 'bob');
      expect(await bob.decode(delivered(body, recipient: 'eve')), isNull);
      expect(await bob.decode(delivered(body, id: 'replayed')), isNull);
      expect(
        await bob.decode(
          delivered((ciphertext: 'invalid', nonce: 'managed-v1')),
        ),
        isNull,
      );
      expect(
        await bob.decode(
          delivered((
            ciphertext: base64Encode(utf8.encode('{}')),
            nonce: 'managed-v1',
          )),
        ),
        isNull,
      );
    },
  );
  test(
    'editing a managed message updates its cached conversation preview',
    () async {
      final previews = ConversationPreviews(bob);
      ChatConversation conversation(({String ciphertext, String nonce}) body) =>
          ChatConversation.fromJson({
            'participantId': 'alice',
            'participantName': 'Alice',
            'lastMessage': {
              'id': 'm1',
              'senderId': 'alice',
              'ciphertext': body.ciphertext,
              'nonce': body.nonce,
              'createdAt': '2026-11-06T00:00:00.000Z',
            },
          });
      final original = await alice.encode('Original', id: 'm1', peerId: 'bob');
      final edited = await alice.encode('Edited', id: 'm1', peerId: 'bob');
      expect(
        (await previews.shown(conversation(original))).lastMessage,
        'Original',
      );
      expect(
        (await previews.shown(conversation(edited))).lastMessage,
        'Edited',
      );
    },
  );

  test('listing cards travel with their message', () async {
    const listing = ChatListing(
      id: 'p1',
      title: 'Villa',
      price: '100',
      imageUrl: 'https://example.test/photo.jpg',
    );
    final body = await alice.encode(
      'Villa',
      id: 'm1',
      peerId: 'bob',
      listing: listing,
    );
    expect((await bob.decode(delivered(body)))?.listing?.id, 'p1');
  });
}
