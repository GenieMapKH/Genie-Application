import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_attachment_service.dart';
import 'package:genie/features/chat/data/chat_attachment_store.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/keys/crypto_service.dart';
import 'package:genie/features/chat/models/chat_attachment.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_emoji_panel.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

import 'chat_fakes.dart';

/// "Encrypts" by reversing the bytes, and refuses a wrong key.
class _ReversingCrypto extends Fake implements CryptoService {
  @override
  ({Uint8List cipher, String key, String nonce}) encryptFile(Uint8List bytes) =>
      (
        cipher: Uint8List.fromList(bytes.reversed.toList()),
        key: 'k',
        nonce: 'n',
      );

  @override
  Uint8List decryptFile(Uint8List cipher, String key, String nonce) {
    if (key != 'k') throw Exception('bad MAC');
    return Uint8List.fromList(cipher.reversed.toList());
  }
}

class _FileStore extends Fake implements ChatRepository {
  final stored = <String, Uint8List>{};
  int downloads = 0;

  @override
  Future<String> uploadEncryptedFile(
    String recipientId,
    Uint8List encrypted,
  ) async {
    final path = fakeAttachment(stored.length + 1).path;
    stored[path] = encrypted;
    return path;
  }

  @override
  Future<Uint8List> downloadEncryptedFile(String path) async {
    downloads++;
    return stored[path]!;
  }
}

/// The device's store of encrypted files, kept in a map.
class _DeviceStore extends Fake implements ChatAttachmentStore {
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String path) async => files[path];

  @override
  Future<void> write(String path, Uint8List encrypted) async =>
      files[path] = encrypted;

  @override
  Future<void> remove(String path) async => files.remove(path);
}

void main() {
  final picture = Uint8List.fromList([1, 2, 3, 4, 5]);

  group('ChatAttachmentService', () {
    late _FileStore store;
    late _DeviceStore device;
    late ChatAttachmentService service;

    /// Another device (or this app after a restart): its own memory.
    ChatAttachmentService receiver({_DeviceStore? on}) => ChatAttachmentService(
      repository: store,
      cryptoService: _ReversingCrypto(),
      store: on ?? _DeviceStore(),
    );

    setUp(() {
      store = _FileStore();
      device = _DeviceStore();
      service = ChatAttachmentService(
        repository: store,
        cryptoService: _ReversingCrypto(),
        store: device,
      );
    });

    Future<ChatAttachment> send(Uint8List bytes) => service.send(
      bytes,
      recipientId: peer,
      name: 'house.jpg',
      mimeType: 'image/jpeg',
    );

    test('uploads only the encrypted bytes', () async {
      final attachment = await send(picture);

      expect(store.stored[attachment.path], [5, 4, 3, 2, 1]);
      expect(attachment.name, 'house.jpg');
      expect(attachment.size, 5);
      expect(attachment.isImage, isTrue);
    });

    test('the other side gets the original file back', () async {
      final attachment = await send(picture);

      expect(await receiver().open(attachment), picture);
    });

    test('a file is downloaded once, however often it is shown', () async {
      final attachment = await send(picture);
      final other = receiver();

      await other.open(attachment);
      await other.open(attachment);

      expect(store.downloads, 1);
    });

    test('only the encrypted file is kept on the device', () async {
      final attachment = await send(picture);
      final otherDevice = _DeviceStore();
      await receiver(on: otherDevice).open(attachment);

      expect(device.files[attachment.path], [5, 4, 3, 2, 1]);
      expect(otherDevice.files[attachment.path], [5, 4, 3, 2, 1]);
    });

    test('after a restart a stored file opens without downloading', () async {
      final attachment = await send(picture);
      final otherDevice = _DeviceStore();
      await receiver(on: otherDevice).open(attachment);

      final restarted = receiver(on: otherDevice);

      expect(await restarted.open(attachment), picture);
      expect(store.downloads, 1);
    });

    test('a stored copy that no longer opens is downloaded again', () async {
      final attachment = await send(picture);
      final otherDevice = _DeviceStore()
        ..files[attachment.path] = Uint8List.fromList([9, 9]);
      final forged = ChatAttachment(
        path: attachment.path,
        key: 'other',
        nonce: attachment.nonce,
        name: attachment.name,
        mimeType: attachment.mimeType,
        size: attachment.size,
      );

      await expectLater(
        receiver(on: otherDevice).open(forged),
        throwsException,
      );
      expect(otherDevice.files, isNot(contains(attachment.path)));
      expect(store.downloads, 1);
    });

    test('a recently opened file is available without waiting', () async {
      final attachment = await send(picture);
      final other = receiver();

      expect(other.cached(attachment), isNull);
      await other.open(attachment);
      expect(other.cached(attachment), picture);
    });

    test('a wrong key opens nothing', () async {
      final attachment = await send(picture);
      final forged = ChatAttachment(
        path: attachment.path,
        key: 'other',
        nonce: attachment.nonce,
        name: attachment.name,
        mimeType: attachment.mimeType,
        size: attachment.size,
      );

      await expectLater(receiver().open(forged), throwsException);
    });

    test('refuses a file over the size limit before uploading', () async {
      final huge = Uint8List(ChatAttachmentService.maxBytes + 1);

      await expectLater(send(huge), throwsA(isA<ChatSendException>()));
      expect(store.stored, isEmpty);
    });
  });

  group('ChatAttachment', () {
    Map<String, dynamic> json({String? path}) => {
      ...fakeAttachment(1).toJson(),
      'path': ?path,
    };

    test('survives the trip through a message', () {
      final original = fakeAttachment(1);

      expect(ChatAttachment.tryParse(original.toJson()), original);
    });

    test('rejects a path that is not three ids', () {
      expect(ChatAttachment.tryParse(json(path: '../../users/me')), isNull);
      expect(ChatAttachment.tryParse(json(path: 'a/b/c')), isNull);
      expect(ChatAttachment.tryParse({'path': fakeAttachment(1).path}), isNull);
      expect(ChatAttachment.tryParse('not a map'), isNull);
    });

    test('knows which conversation it is stored under', () {
      final attachment = fakeAttachment(1);

      expect(
        attachment.belongsTo(
          senderId: '11111111-1111-4111-8111-111111111111',
          recipientId: '22222222-2222-4222-8222-222222222222',
        ),
        isTrue,
      );
      expect(
        attachment.belongsTo(
          senderId: '22222222-2222-4222-8222-222222222222',
          recipientId: '11111111-1111-4111-8111-111111111111',
        ),
        isFalse,
      );
    });
  });

  group('sending a picture', () {
    late FakeChatRepository repository;
    late FakeChatSocket socket;
    late FakeCipher cipher;
    late FakeAttachmentService attachments;
    late ConversationsNotifier conversations;
    late ActiveChatNotifier chat;

    setUp(() async {
      repository = FakeChatRepository();
      socket = FakeChatSocket();
      cipher = FakeCipher();
      attachments = FakeAttachmentService();
      conversations = ConversationsNotifier(
        repository: repository,
        socketService: socket,
        cipher: cipher,
      );
      chat = ActiveChatNotifier(
        userId: me,
        participantId: peer,
        repository: repository,
        socketService: socket,
        setupService: FakeSetupService(),
        cipher: cipher,
        attachments: attachments,
        conversations: conversations,
      );
      await chat.open(askPin: neverAskPin);
    });

    tearDown(() {
      chat.dispose();
      conversations.dispose();
    });

    Future<void> sendPicture() =>
        chat.sendImage(picture, name: 'house.jpg', mimeType: 'image/jpeg');

    test('shows it at once, uploads it, then sends where it is', () async {
      final sending = sendPicture();

      final pending = chat.state.messages.single;
      expect(pending.localImage, picture);
      expect(pending.status, ChatMessageStatus.sending);

      await sending;

      final sent = chat.state.messages.single;
      expect(sent.status, ChatMessageStatus.sent);
      expect(attachments.uploads, [picture]);
      expect(cipher.sealedAttachments.single, sent.attachment);
      expect(sent.attachment!.name, 'house.jpg');
      expect(socket.sent, hasLength(1));
    });

    test('a failed upload is reported and nothing is sent', () async {
      attachments.uploadError = const ChatSendException(
        'Could not upload the file.',
      );

      await sendPicture();

      expect(chat.state.messages.single.status, ChatMessageStatus.failed);
      expect(chat.state.sendError, 'Could not upload the file.');
      expect(socket.sent, isEmpty);
    });

    test('retrying after the upload succeeded does not upload again', () async {
      socket.sendError = const ChatSendException('offline');
      await sendPicture();

      socket.sendError = null;
      await chat.retry(chat.state.messages.single.id);

      expect(attachments.uploads, hasLength(1));
      expect(chat.state.messages.single.status, ChatMessageStatus.sent);
    });

    test('retrying after a failed upload uploads it then', () async {
      attachments.uploadError = const ChatSendException('offline');
      await sendPicture();

      attachments.uploadError = null;
      await chat.retry(chat.state.messages.single.id);

      expect(attachments.uploads, hasLength(1));
      expect(chat.state.messages.single.status, ChatMessageStatus.sent);
    });

    test('a received picture arrives with its attachment', () async {
      cipher.incomingAttachments['m1'] = fakeAttachment(7);

      socket.messages.add(encrypted('m1', '', from: peer));
      await Future<void>.delayed(Duration.zero);

      expect(chat.state.messages.single.attachment, fakeAttachment(7));
    });
  });

  group('in the conversation', () {
    late FakeChatRepository repository;
    late FakeChatSocket socket;
    late FakeCipher cipher;
    late FakeAttachmentService attachments;

    setUp(() {
      repository = FakeChatRepository();
      socket = FakeChatSocket();
      cipher = FakeCipher();
      attachments = FakeAttachmentService();
    });

    Future<void> openChat(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (ref) async => UserProfile(
                id: me,
                role: 'user',
                createdAt: DateTime.utc(2026),
              ),
            ),
            chatRepositoryProvider.overrideWithValue(repository),
            chatSocketServiceProvider.overrideWithValue(socket),
            e2eeSetupServiceProvider.overrideWithValue(FakeSetupService()),
            messageCipherProvider.overrideWith((ref, userId) => cipher),
            chatAttachmentServiceProvider.overrideWithValue(attachments),
          ],
          child: const MaterialApp(
            home: ChatConversationPage(
              participantId: peer,
              participantName: 'Dara',
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }

    testWidgets('a received picture is downloaded and shown', (tester) async {
      final attachment = fakeAttachment(1);
      attachments.files[attachment.path] = tinyPng;
      cipher.incomingAttachments['m1'] = attachment;
      repository.history = [encrypted('m1', '', from: peer)];

      await openChat(tester);
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Photo unavailable. Tap to retry.'), findsNothing);
    });

    testWidgets('a picture that cannot be fetched says so', (tester) async {
      cipher.incomingAttachments['m1'] = fakeAttachment(1);
      repository.history = [encrypted('m1', '', from: peer)];

      await openChat(tester);
      await tester.pump();

      expect(find.text('Photo unavailable. Tap to retry.'), findsOneWidget);
    });

    testWidgets('emojis are typed from the panel and sent', (tester) async {
      await openChat(tester);

      await tester.enterText(find.byType(TextField), 'Deal');
      await tester.tap(find.byIcon(Icons.sentiment_satisfied_alt).first);
      await tester.pump();
      expect(find.byType(ChatEmojiPanel), findsOneWidget);

      await tester.tap(find.text('😀'));
      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();
      await tester.pump();

      expect(socket.sent.single.ciphertext, 'sealed:Deal😀');
      expect(find.text('Deal😀'), findsOneWidget);
    });

    testWidgets('the emoji panel gives way to the keyboard', (tester) async {
      await openChat(tester);

      await tester.tap(find.byIcon(Icons.sentiment_satisfied_alt).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pump();

      expect(find.byType(ChatEmojiPanel), findsNothing);
    });
  });
}
