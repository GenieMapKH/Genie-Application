import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/models/chat_message_action_problem.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/message_deletion.dart';
import 'package:tilomnov/features/chat/providers/active_chat_provider.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';

import 'chat_fakes.dart';

/// Replying to, editing and deleting single messages in an open chat.
void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;
  late FakeCipher cipher;
  late ConversationsNotifier conversations;
  late ActiveChatNotifier chat;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// A stored message sent a few minutes ago, so it can still be edited.
  EncryptedMessage recent(
    String id,
    String text, {
    required String from,
    EncryptedMessage? replyTo,
  }) {
    return EncryptedMessage(
      id: id,
      senderId: from,
      recipientId: from == me ? peer : me,
      ciphertext: 'sealed:$text',
      nonce: 'nonce',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      replyTo: replyTo,
    );
  }

  ChatMessage messageWithId(String id) =>
      chat.state.messages.singleWhere((m) => m.id == id);

  List<String> ids() => chat.state.messages.map((m) => m.id).toList();

  DioException httpError(int status) => DioException(
    requestOptions: RequestOptions(),
    response: Response(requestOptions: RequestOptions(), statusCode: status),
  );

  setUp(() {
    repository = FakeChatRepository();
    socket = FakeChatSocket();
    cipher = FakeCipher();
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
      attachments: FakeAttachmentService(),
      conversations: conversations,
    );
  });

  tearDown(() {
    chat.dispose();
    conversations.dispose();
  });

  group('replying', () {
    test('seals and sends which message the reply quotes', () async {
      repository.history = [recent('m1', 'Is it available?', from: peer)];
      await chat.open(askPin: neverAskPin);

      await chat.sendMessage('Yes', replyTo: messageWithId('m1'));

      final reply = chat.state.messages.last;
      expect(reply.status, ChatMessageStatus.sent);
      expect(reply.replyTo?.messageId, 'm1');
      expect(reply.replyTo?.text, 'Is it available?');
      expect(cipher.sealedReplies[reply.id], 'm1');
      expect(socket.sentReplyIds[reply.id], 'm1');
    });

    test('shows the quote of a reply loaded from the server', () async {
      final quoted = recent('m1', 'Is it available?', from: me);
      cipher.sealedReplies['m2'] = 'm1';
      repository.history = [
        quoted,
        recent('m2', 'Yes', from: peer, replyTo: quoted),
      ];

      await chat.open(askPin: neverAskPin);

      expect(messageWithId('m2').replyTo?.text, 'Is it available?');
      expect(messageWithId('m2').replyTo?.senderId, me);
    });

    test('an ordinary message quotes nothing', () async {
      await chat.open(askPin: neverAskPin);

      await chat.sendMessage('Hello');

      expect(chat.state.messages.single.replyTo, isNull);
      expect(socket.sentReplyIds, isEmpty);
    });
  });

  group('editing', () {
    test('seals the new text and shows it, marked as edited', () async {
      repository.history = [recent('m1', 'See you at 5', from: me)];
      await chat.open(askPin: neverAskPin);

      final problem = await chat.editMessage('m1', 'See you at 6');

      expect(problem, isNull);
      expect(repository.messageChanges, ['edit m1 sealed:See you at 6']);
      expect(messageWithId('m1').text, 'See you at 6');
      expect(messageWithId('m1').editedAt, isNotNull);
    });

    test('updates the quote in replies to the edited message', () async {
      final quoted = recent('m1', 'See you at 5', from: me);
      cipher.sealedReplies['m2'] = 'm1';
      repository.history = [
        quoted,
        recent('m2', 'OK', from: peer, replyTo: quoted),
      ];
      await chat.open(askPin: neverAskPin);

      await chat.editMessage('m1', 'See you at 6');

      expect(messageWithId('m2').replyTo?.text, 'See you at 6');
    });

    test('keeps what the reply quotes when a reply is edited', () async {
      final quoted = recent('m1', 'Is it available?', from: peer);
      cipher.sealedReplies['m2'] = 'm1';
      repository.history = [
        quoted,
        recent('m2', 'Yes', from: me, replyTo: quoted),
      ];
      await chat.open(askPin: neverAskPin);

      await chat.editMessage('m2', 'Yes, it is');

      expect(cipher.sealedReplies['m2'], 'm1');
      expect(messageWithId('m2').replyTo?.messageId, 'm1');
    });

    test(
      'is refused an hour after sending, without asking the server',
      () async {
        repository.history = [encrypted('m1', 'Old news', from: me)];
        await chat.open(askPin: neverAskPin);

        expect(
          await chat.editMessage('m1', 'New news'),
          ChatMessageActionProblem.editTooLate,
        );
        expect(repository.messageChanges, isEmpty);
        expect(messageWithId('m1').text, 'Old news');
      },
    );

    test('says it is too late when the server says so', () async {
      repository.history = [recent('m1', 'See you at 5', from: me)];
      await chat.open(askPin: neverAskPin);
      repository.messageChangeError = httpError(403);

      expect(
        await chat.editMessage('m1', 'See you at 6'),
        ChatMessageActionProblem.editTooLate,
      );
      expect(messageWithId('m1').text, 'See you at 5');
    });

    test('keeps the old text when the edit cannot be sent', () async {
      repository.history = [recent('m1', 'See you at 5', from: me)];
      await chat.open(askPin: neverAskPin);
      repository.messageChangeError = httpError(503);

      expect(
        await chat.editMessage('m1', 'See you at 6'),
        ChatMessageActionProblem.failed,
      );
      expect(messageWithId('m1').text, 'See you at 5');
    });

    test("cannot edit the other person's message", () async {
      repository.history = [recent('m1', 'Hello', from: peer)];
      await chat.open(askPin: neverAskPin);

      expect(
        await chat.editMessage('m1', 'Bye'),
        ChatMessageActionProblem.editTooLate,
      );
      expect(repository.messageChanges, isEmpty);
    });

    test("shows the other person's edit as it happens", () async {
      repository.history = [recent('m1', 'See you at 5', from: peer)];
      await chat.open(askPin: neverAskPin);

      socket.editedMessages.add(
        EncryptedMessage(
          id: 'm1',
          senderId: peer,
          recipientId: me,
          ciphertext: 'sealed:See you at 6',
          nonce: 'nonce',
          createdAt: DateTime.now(),
          editedAt: DateTime.now(),
        ),
      );
      await settle();

      expect(messageWithId('m1').text, 'See you at 6');
      expect(messageWithId('m1').editedAt, isNotNull);
    });
  });

  group('deleting', () {
    test(
      'for everyone removes my message and its file, leaving nothing',
      () async {
        cipher.incomingAttachments['m1'] = fakeAttachment(1);
        repository.history = [
          recent('m1', '', from: me),
          recent('m2', 'Hi', from: peer),
        ];
        await chat.open(askPin: neverAskPin);

        final problem = await chat.deleteMessage('m1', forEveryone: true);

        expect(problem, isNull);
        expect(repository.messageChanges, [
          'delete m1 forEveryone ${fakeAttachment(1).path}',
        ]);
        expect(ids(), ['m2']);
      },
    );

    test('takes the quote out of replies to the deleted message', () async {
      final quoted = recent('m1', 'Secret', from: me);
      cipher.sealedReplies['m2'] = 'm1';
      repository.history = [
        quoted,
        recent('m2', 'OK', from: peer, replyTo: quoted),
      ];
      await chat.open(askPin: neverAskPin);

      await chat.deleteMessage('m1', forEveryone: true);

      expect(ids(), ['m2']);
      expect(messageWithId('m2').replyTo, isNull);
    });

    test("deletes the other person's message for me only", () async {
      repository.history = [recent('m1', 'Hi', from: peer)];
      await chat.open(askPin: neverAskPin);

      await chat.deleteMessage('m1', forEveryone: true);

      expect(repository.messageChanges, ['delete m1']);
      expect(ids(), isEmpty);
    });

    test('a message already deleted is simply removed', () async {
      repository.history = [recent('m1', 'Hi', from: me)];
      await chat.open(askPin: neverAskPin);
      repository.messageChangeError = httpError(404);

      expect(await chat.deleteMessage('m1', forEveryone: false), isNull);
      expect(ids(), isEmpty);
    });

    test('keeps the message when the delete cannot be sent', () async {
      repository.history = [recent('m1', 'Hi', from: me)];
      await chat.open(askPin: neverAskPin);
      repository.messageChangeError = httpError(503);

      expect(
        await chat.deleteMessage('m1', forEveryone: true),
        ChatMessageActionProblem.failed,
      );
      expect(ids(), ['m1']);
    });

    test('a message that was never sent is only removed here', () async {
      await chat.open(askPin: neverAskPin);
      socket.sendError = Exception('offline');
      await chat.sendMessage('unsent');
      final failed = chat.state.messages.single;
      expect(failed.status, ChatMessageStatus.failed);

      await chat.deleteMessage(failed.id, forEveryone: true);

      expect(chat.state.messages, isEmpty);
      expect(repository.messageChanges, isEmpty);
    });

    test('disappears as soon as it is deleted elsewhere', () async {
      repository.history = [
        recent('m1', 'Hi', from: peer),
        recent('m2', 'Hello', from: me),
      ];
      await chat.open(askPin: neverAskPin);

      socket.deletedMessages.add(
        const MessageDeletion(messageId: 'm1', participantId: peer),
      );
      socket.deletedMessages.add(
        const MessageDeletion(messageId: 'm2', participantId: 'someone-else'),
      );
      await settle();

      expect(ids(), ['m2']);
    });

    test('the chat list is reloaded so its last message is right', () async {
      await settle();
      final before = repository.conversationRequests;

      socket.deletedMessages.add(
        const MessageDeletion(messageId: 'm1', participantId: peer),
      );
      await settle();

      expect(repository.conversationRequests, before + 1);
    });
  });

  group('who may do what', () {
    final now = DateTime.now();
    ChatMessage message({
      String from = me,
      String text = 'Hi',
      Duration age = const Duration(minutes: 5),
      ChatMessageStatus status = ChatMessageStatus.sent,
    }) => ChatMessage(
      id: 'm1',
      senderId: from,
      recipientId: from == me ? peer : me,
      text: text,
      createdAt: now.subtract(age),
      status: status,
    );

    test('my own text can be edited for an hour', () {
      expect(message().canBeEditedBy(me, now), isTrue);
      expect(
        message(age: const Duration(minutes: 59)).canBeEditedBy(me, now),
        isTrue,
      );
      expect(
        message(age: const Duration(hours: 1)).canBeEditedBy(me, now),
        isFalse,
      );
    });

    test('nothing else can be edited', () {
      expect(message(from: peer).canBeEditedBy(me, now), isFalse);
      expect(message(text: '').canBeEditedBy(me, now), isFalse);
      expect(
        message(text: ChatMessage.undecryptableText).canBeEditedBy(me, now),
        isFalse,
      );
      expect(
        message(status: ChatMessageStatus.failed).canBeEditedBy(me, now),
        isFalse,
      );
    });

    test('only a sent, readable message can be replied to', () {
      expect(message().canReply, isTrue);
      expect(message(status: ChatMessageStatus.sending).canReply, isFalse);
      expect(message(text: ChatMessage.undecryptableText).canReply, isFalse);
    });
  });
}
