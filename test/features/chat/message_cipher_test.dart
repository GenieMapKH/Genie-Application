import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/data/chat_backup_repository.dart';
import 'package:tilomnov/features/chat/e2ee/keys/crypto_service.dart';
import 'package:tilomnov/features/chat/e2ee/keys/key_service.dart';
import 'package:tilomnov/features/chat/e2ee/keys/message_cipher.dart';
import 'package:tilomnov/features/chat/e2ee/message_reader.dart';
import 'package:tilomnov/features/chat/e2ee/keys/peer_key_store.dart';
import 'package:tilomnov/features/chat/models/chat_attachment.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_listing.dart';
import 'package:tilomnov/features/chat/models/chat_send_problem.dart';
import 'package:sodium_libs/sodium_libs.dart';

const alice = 'alice';
const bob = 'bob';

/// A secret key that remembers which public key byte it belongs to.
class _FakeSecureKey extends Fake implements SecureKey {
  final int owner;
  _FakeSecureKey(this.owner);
}

/// Like a real shared key: what two key pairs seal, only those two open,
/// from either side.
class _FakeCrypto extends Fake implements CryptoService {
  String _shared(Uint8List publicKey, SecureKey secretKey) {
    final own = (secretKey as _FakeSecureKey).owner;
    return '${min(own, publicKey.first)}-${max(own, publicKey.first)}';
  }

  @override
  Map<String, String> encryptMessage(
    String plaintext,
    Uint8List recipientPublicKey,
    SecureKey senderPrivateKey,
  ) => {
    'ciphertext': '${_shared(recipientPublicKey, senderPrivateKey)}|$plaintext',
    'nonce': 'n',
  };

  @override
  String decryptMessage(
    String ciphertextBase64,
    String nonceBase64,
    Uint8List senderPublicKey,
    SecureKey recipientPrivateKey,
  ) {
    final split = ciphertextBase64.indexOf('|');
    final shared = _shared(senderPublicKey, recipientPrivateKey);
    if (ciphertextBase64.substring(0, split) != shared) {
      throw Exception('bad MAC');
    }
    return ciphertextBase64.substring(split + 1);
  }

  @override
  Uint8List fingerprint(Uint8List publicKeyA, Uint8List publicKeyB) {
    final low = min(publicKeyA.first, publicKeyB.first);
    final high = max(publicKeyA.first, publicKeyB.first);
    return Uint8List.fromList(
      List.generate(32, (i) => (low * 31 + high * 17 + i * 7) % 256),
    );
  }
}

class _FakeKeys extends Fake implements KeyService {
  /// Own public key byte per user; a user without one has no keys here.
  final Map<String, int> keys;
  _FakeKeys(this.keys);

  @override
  Future<KeyPair?> getIdentityKeyPair(String userId) async {
    final key = keys[userId];
    return key == null
        ? null
        : KeyPair(
            publicKey: Uint8List.fromList([key]),
            secretKey: _FakeSecureKey(key),
          );
  }
}

/// The server's key directory: the public key byte it lists per user.
class _FakeKeyServer extends Fake implements ChatBackupRepository {
  final Map<String, int> listed;
  bool offline = false;
  int requests = 0;

  _FakeKeyServer(this.listed);

  @override
  Future<String> fetchPublicKey(String userId) async {
    requests++;
    final options = RequestOptions(path: '/chat/keys/$userId');
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final key = listed[userId];
    if (key == null) {
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404),
      );
    }
    return base64Encode([key]);
  }
}

class _MemoryKeyStore extends Fake implements PeerKeyStore {
  final keys = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String peerId) async => keys[peerId];

  @override
  Future<void> write(String peerId, Uint8List publicKey) async =>
      keys[peerId] = publicKey;
}

void main() {
  const aliceKey = 1;
  const bobKey = 7;

  late _FakeKeyServer server;
  late _MemoryKeyStore aliceStore;
  late DateTime now;
  late MessageCipher aliceCipher;
  late MessageCipher bobCipher;

  MessageCipher cipherFor(
    String userId,
    Map<String, int> ownKeys, {
    PeerKeyStore? store,
  }) {
    return MessageCipher(
      userId: userId,
      cryptoService: _FakeCrypto(),
      keyService: _FakeKeys(ownKeys),
      keyRepository: server,
      trustedKeys: store ?? _MemoryKeyStore(),
      now: () => now,
    );
  }

  /// What the server stores and delivers for a message Alice sends to Bob.
  Future<EncryptedMessage> sentByAlice(String id, String text) async {
    final sealed = await aliceCipher.encrypt(text, id: id, peerId: bob);
    return EncryptedMessage(
      id: id,
      senderId: alice,
      recipientId: bob,
      ciphertext: sealed.ciphertext,
      nonce: sealed.nonce,
      createdAt: now,
    );
  }

  EncryptedMessage relabelled(
    EncryptedMessage message, {
    String? id,
    String? senderId,
    String? recipientId,
  }) {
    return EncryptedMessage(
      id: id ?? message.id,
      senderId: senderId ?? message.senderId,
      recipientId: recipientId ?? message.recipientId,
      ciphertext: message.ciphertext,
      nonce: message.nonce,
      createdAt: message.createdAt,
    );
  }

  setUp(() {
    server = _FakeKeyServer({alice: aliceKey, bob: bobKey});
    aliceStore = _MemoryKeyStore();
    now = DateTime.utc(2026, 1, 1, 12);
    aliceCipher = cipherFor(alice, {alice: aliceKey}, store: aliceStore);
    bobCipher = cipherFor(bob, {bob: bobKey});
  });

  group('a conversation', () {
    test('what one person seals, both can read', () async {
      final message = await sentByAlice('m1', 'hello');

      expect(message.ciphertext, isNot(startsWith('hello')));
      expect(await bobCipher.decrypt(message), (
        id: 'm1',
        text: 'hello',
        attachment: null,
        replyToId: null,
        listing: null,
      ));
      expect(await aliceCipher.decrypt(message), (
        id: 'm1',
        text: 'hello',
        attachment: null,
        replyToId: null,
        listing: null,
      ));
    });

    test(
      'messages from before senders were named are still readable',
      () async {
        final legacy = EncryptedMessage(
          id: 'old',
          senderId: alice,
          recipientId: bob,
          ciphertext: '1-7|see you at 5',
          nonce: 'n',
          createdAt: now,
        );

        expect(await bobCipher.decrypt(legacy), (
          id: null,
          text: 'see you at 5',
          attachment: null,
          replyToId: null,
          listing: null,
        ));
      },
    );

    test('nothing can be read on a device without keys', () async {
      final message = await sentByAlice('m1', 'hello');
      final noKeys = cipherFor(bob, {});
      server.requests = 0;

      expect(await noKeys.decrypt(message), isNull);
      expect(server.requests, 0);
    });

    test('nothing can be sent from a device without keys', () async {
      final noKeys = cipherFor(alice, {});

      await expectLater(
        noKeys.encrypt('hello', id: 'm1', peerId: bob),
        throwsA(isA<ChatEncryptionException>()),
      );
    });
  });

  group('a reply', () {
    Future<EncryptedMessage> replyByAlice(
      String id,
      String text, {
      required String replyToId,
      EncryptedMessage? quotedByServer,
    }) async {
      final sealed = await aliceCipher.encrypt(
        text,
        id: id,
        peerId: bob,
        replyToId: replyToId,
      );
      return EncryptedMessage(
        id: id,
        senderId: alice,
        recipientId: bob,
        ciphertext: sealed.ciphertext,
        nonce: sealed.nonce,
        createdAt: now,
        replyTo: quotedByServer,
      );
    }

    test('names the message it replies to inside the sealed text', () async {
      final reply = await replyByAlice('m2', 'yes', replyToId: 'm1');

      expect((await bobCipher.decrypt(reply))?.replyToId, 'm1');
    });

    test('shows the quoted message, opened on this device', () async {
      final quoted = await sentByAlice('m1', 'Is it still available?');
      final reply = await replyByAlice(
        'm2',
        'I mean the house',
        replyToId: 'm1',
        quotedByServer: quoted,
      );

      final read = await ChatMessageReader(bobCipher).read(reply);

      expect(read.replyToId, 'm1');
      expect(read.replyTo?.messageId, 'm1');
      expect(read.replyTo?.senderId, alice);
      expect(read.replyTo?.text, 'Is it still available?');
    });

    test('cannot be made to quote another message by the server', () async {
      final other = await sentByAlice('m0', 'something else');
      final reply = await replyByAlice(
        'm2',
        'yes',
        replyToId: 'm1',
        quotedByServer: other,
      );

      expect((await ChatMessageReader(bobCipher).read(reply)).replyTo, isNull);
    });

    test('quotes nothing once the quoted message is deleted', () async {
      final reply = await replyByAlice('m2', 'yes', replyToId: 'm1');

      final read = await ChatMessageReader(bobCipher).read(reply);

      expect(read.text, 'yes');
      expect(read.replyTo, isNull);
      // Kept, so an edit seals the same reply again.
      expect(read.replyToId, 'm1');
    });
  });

  group('a file sent with a message', () {
    ChatAttachment fileBetween(String senderId, String recipientId) {
      return ChatAttachment(
        path: '$senderId/$recipientId/33333333-3333-4333-8333-333333333333',
        key: 'file-key',
        nonce: 'file-nonce',
        name: 'contract.jpg',
        mimeType: 'image/jpeg',
        size: 1234,
      );
    }

    Future<EncryptedMessage> sentWith(ChatAttachment attachment) async {
      final sealed = await aliceCipher.encrypt(
        '',
        id: 'm1',
        peerId: bob,
        attachment: attachment,
      );
      return EncryptedMessage(
        id: 'm1',
        senderId: alice,
        recipientId: bob,
        ciphertext: sealed.ciphertext,
        nonce: sealed.nonce,
        createdAt: now,
      );
    }

    // The fake ids are not UUIDs, so use real-looking ones for the path.
    const aliceId = '11111111-1111-4111-8111-111111111111';
    const bobId = '22222222-2222-4222-8222-222222222222';

    test('its key travels inside the sealed message', () async {
      final attachment = fileBetween(aliceId, bobId);
      final sealed = await aliceCipher.encrypt(
        'here it is',
        id: 'm1',
        peerId: bob,
        attachment: attachment,
      );

      expect(sealed.ciphertext, contains('file-key'));
      expect(sealed.ciphertext, startsWith('1-7|'));
    });

    test('is dropped when it points outside this conversation', () async {
      // The path names two other people: the message's sender and
      // recipient are "alice" and "bob", so this file is not theirs.
      final message = await sentWith(fileBetween(aliceId, bobId));

      final opened = await bobCipher.decrypt(message);

      expect(opened!.text, '');
      expect(opened.attachment, isNull);
    });
  });

  group('a server that tampers with messages', () {
    test("cannot show my own message as the other person's", () async {
      final message = await sentByAlice('m1', 'I agree to pay 500');

      final reflected = relabelled(message, senderId: bob, recipientId: alice);

      expect(await aliceCipher.decrypt(reflected), isNull);
    });

    test('cannot replay an old message as a new one', () async {
      final message = await sentByAlice('m1', 'send the deposit');

      final replayed = relabelled(message, id: 'fresh-row-id');

      // It still opens, but under the id it was sent with, so the chat
      // recognises it as the message it already has.
      expect((await bobCipher.decrypt(replayed))!.id, 'm1');
    });

    test('cannot make a message readable after changing a byte', () async {
      final message = await sentByAlice('m1', 'hello');

      final tampered = EncryptedMessage(
        id: message.id,
        senderId: message.senderId,
        recipientId: message.recipientId,
        ciphertext: '9-9|${message.ciphertext.split('|').last}',
        nonce: message.nonce,
        createdAt: message.createdAt,
      );

      expect(await bobCipher.decrypt(tampered), isNull);
    });
  });

  group("the other person's key", () {
    test('is remembered the first time it is seen', () async {
      expect(await aliceCipher.checkPeerKey(bob), PeerKeyStatus.trusted);
      expect(aliceStore.keys[bob], [bobKey]);
    });

    test('is read from this device afterwards, not from the server', () async {
      final message = await sentByAlice('m1', 'hello');
      final afterRestart = cipherFor(alice, {
        alice: aliceKey,
      }, store: aliceStore);
      server.requests = 0;

      for (var i = 0; i < 50; i++) {
        expect(await afterRestart.decrypt(message), isNotNull);
      }

      expect(server.requests, 0);
    });

    test(
      'opens a message with no network when it is already trusted',
      () async {
        final message = await sentByAlice('m1', 'hello');
        final afterRestart = cipherFor(bob, {bob: bobKey});
        // Bob has never met Alice on this phone: nothing is trusted yet.
        server.requests = 0;

        expect(await afterRestart.decrypt(message, askServer: false), isNull);
        expect(server.requests, 0);

        await afterRestart.checkPeerKey(alice);
        server.requests = 0;
        expect(await afterRestart.decrypt(message, askServer: false), (
          id: 'm1',
          text: 'hello',
          attachment: null,
          replyToId: null,
          listing: null,
        ));
        expect(server.requests, 0);
      },
    );

    test('is not silently replaced when the server lists another', () async {
      await sentByAlice('m1', 'hello');
      server.listed[bob] = 66; // an attacker's key, or a real reset
      now = now.add(const Duration(minutes: 6));

      expect(await aliceCipher.checkPeerKey(bob), PeerKeyStatus.changed);
      await expectLater(
        aliceCipher.encrypt('my card number', id: 'm2', peerId: bob),
        throwsA(isA<PeerKeyChangedException>()),
      );
      expect(aliceStore.keys[bob], [bobKey]);
    });

    test('keeps refusing until the user accepts the new key', () async {
      await sentByAlice('m1', 'hello');
      server.listed[bob] = 9;
      await aliceCipher.checkPeerKey(bob);

      await expectLater(
        aliceCipher.encrypt('again', id: 'm2', peerId: bob),
        throwsA(isA<PeerKeyChangedException>()),
      );

      await aliceCipher.trustCurrentPeerKey(bob);
      final sealed = await aliceCipher.encrypt('ok', id: 'm3', peerId: bob);

      expect(sealed.ciphertext, startsWith('1-9|'));
      expect(await aliceCipher.checkPeerKey(bob), PeerKeyStatus.trusted);
    });

    test(
      'is checked again before sending once the last check is old',
      () async {
        await sentByAlice('m1', 'one');
        await sentByAlice('m2', 'two');
        expect(server.requests, 1);

        now = now.add(const Duration(minutes: 6));
        await sentByAlice('m3', 'three');

        expect(server.requests, 2);
      },
    );

    test('must exist before anything can be sent', () async {
      server.listed.remove(bob);

      await expectLater(
        aliceCipher.encrypt('hello', id: 'm1', peerId: bob),
        throwsA(
          isA<ChatEncryptionException>().having(
            (e) => e.problem,
            'problem',
            ChatSendProblem.peerNotReady,
          ),
        ),
      );
    });

    test('cannot be checked offline, and says so', () async {
      server.offline = true;

      await expectLater(
        aliceCipher.encrypt('hello', id: 'm1', peerId: bob),
        throwsA(
          isA<ChatEncryptionException>().having(
            (e) => e.problem,
            'problem',
            ChatSendProblem.noConnection,
          ),
        ),
      );
    });

    test('being unreachable does not crash reading', () async {
      final message = await sentByAlice('m1', 'hello');
      server.offline = true;

      expect(await bobCipher.decrypt(message), isNull);
    });
  });

  group('the security code', () {
    test('is the same on both phones', () async {
      await aliceCipher.checkPeerKey(bob);
      await bobCipher.checkPeerKey(alice);

      final code = await aliceCipher.safetyCode(bob);

      expect(code, matches(RegExp(r'^\d{5}( \d{5}){5}$')));
      expect(await bobCipher.safetyCode(alice), code);
    });

    test('differs when someone swapped a key in between', () async {
      await aliceCipher.checkPeerKey(bob);
      // Bob's phone is given an attacker's key instead of Alice's.
      server.listed[alice] = 66;
      await bobCipher.checkPeerKey(alice);

      expect(
        await bobCipher.safetyCode(alice),
        isNot(await aliceCipher.safetyCode(bob)),
      );
    });

    test("is not available before the other person's key is known", () async {
      expect(await aliceCipher.safetyCode(bob), isNull);
    });
  });

  group('a listing card', () {
    const listing = ChatListing(
      id: 'p-1',
      title: 'Villa near Riverside',
      price: r'$ 120,000',
      imageUrl: 'https://cdn.example/p-1.thumb.jpg',
    );

    test('travels inside the sealed message, beside its text', () async {
      final sealed = await aliceCipher.encrypt(
        listing.fallbackText,
        id: 'm3',
        peerId: bob,
        listing: listing,
      );
      final opened = await bobCipher.decrypt(
        EncryptedMessage(
          id: 'm3',
          senderId: alice,
          recipientId: bob,
          ciphertext: sealed.ciphertext,
          nonce: sealed.nonce,
          createdAt: now,
        ),
      );

      expect(opened?.text, '\u{1F3E0} Villa near Riverside · \$ 120,000');
      expect(opened?.listing?.id, 'p-1');
      expect(opened?.listing?.imageUrl, 'https://cdn.example/p-1.thumb.jpg');
    });

    test('an ordinary message carries none', () async {
      final message = await sentByAlice('m1', 'hello');
      expect((await bobCipher.decrypt(message))?.listing, isNull);
    });

    test('keeps only an https picture, and ignores what is not a card', () {
      expect(
        ChatListing.tryParse({
          'id': 'p',
          'title': 't',
          'price': '1',
          'image': 'http://plain.example/x.jpg',
        })?.imageUrl,
        isNull,
      );
      expect(ChatListing.tryParse({'id': 'p', 'title': 't'}), isNull);
      expect(ChatListing.tryParse('p-1'), isNull);
    });
  });
}
