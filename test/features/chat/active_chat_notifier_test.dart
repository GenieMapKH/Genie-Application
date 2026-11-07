import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/data/chat_socket_service.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_send_problem.dart';
import 'package:tilomnov/features/chat/providers/active_chat_provider.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';

import 'chat_fakes.dart';

void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;
  late FakeCipher cipher;
  late FakeAttachmentService attachments;
  late ConversationsNotifier conversations;
  late ActiveChatNotifier chat;

  /// Lets queued stream events and their handlers run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  List<String> texts() => chat.state.messages.map((m) => m.text).toList();

  setUp(() {
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
      cipher: cipher,
      attachments: attachments,
      conversations: conversations,
    );
  });

  tearDown(() {
    chat.dispose();
    conversations.dispose();
  });

  group('open', () {
    test('loads the history and keeps who sent each message', () async {
      repository.history = [
        encrypted('m1', 'Is it still available?', from: me),
        encrypted('m2', 'Yes it is', from: peer),
      ];

      await chat.open();

      expect(chat.state.status, ActiveChatStatus.ready);
      expect(texts(), ['Is it still available?', 'Yes it is']);
      expect(chat.state.messages.map((m) => m.senderId), [me, peer]);
      expect(repository.markedRead, [peer]);
    });

    test('shows a placeholder for a message it cannot decrypt', () async {
      repository.history = [
        EncryptedMessage(
          id: 'old',
          senderId: peer,
          recipientId: me,
          ciphertext: 'made-with-replaced-keys',
          nonce: 'nonce',
          createdAt: DateTime.utc(2026),
        ),
      ];

      await chat.open();

      expect(texts(), [ActiveChatNotifier.undecryptableText]);
    });

    test('can be retried after a failure', () async {
      await chat.open();

      repository.history = [encrypted('m1', 'hello', from: peer)];
      await chat.open();

      expect(chat.state.status, ActiveChatStatus.ready);
      expect(texts(), ['hello']);
    });
  });

  group('receiving', () {
    test(
      'adds a live message from the other person and marks it read',
      () async {
        await chat.open();
        repository.markedRead.clear();

        socket.messages.add(encrypted('m1', 'hi there', from: peer));
        await settle();

        expect(texts(), ['hi there']);
        expect(repository.markedRead, [peer]);
      },
    );

    test('never shows the same message twice', () async {
      repository.history = [encrypted('m1', 'hi', from: peer)];
      await chat.open();

      socket.messages.add(encrypted('m1', 'hi', from: peer));
      socket.messages.add(encrypted('m1', 'hi', from: peer));
      await settle();

      expect(texts(), ['hi']);
    });

    test('ignores messages that belong to another conversation', () async {
      await chat.open();

      socket.messages.add(encrypted('m1', 'psst', from: 'someone-else'));
      await settle();

      expect(chat.state.messages, isEmpty);
    });

    test(
      'shows a message this user sent from another device as theirs',
      () async {
        await chat.open();
        repository.markedRead.clear();

        socket.messages.add(encrypted('m1', 'sent from my tablet', from: me));
        await settle();

        expect(chat.state.messages.single.senderId, me);
        expect(repository.markedRead, isEmpty);
      },
    );

    test('keeps live messages in the order they arrived', () async {
      await chat.open();

      for (final text in ['one', 'two', 'three']) {
        socket.messages.add(encrypted(text, text, from: peer));
      }
      await settle();

      expect(texts(), ['one', 'two', 'three']);
    });

    test('receives new messages without legacy key recovery', () async {
      await chat.open();

      socket.messages.add(encrypted('m1', 'hi', from: peer));
      await settle();

      expect(texts(), ['hi']);
    });
  });

  group('sending', () {
    setUp(() => chat.open());

    test('shows the message at once, as mine, then confirms it', () async {
      final sending = chat.sendMessage('hello');

      final pending = chat.state.messages.single;
      expect(pending.text, 'hello');
      expect(pending.senderId, me);
      expect(pending.status, ChatMessageStatus.sending);

      await sending;

      final sent = chat.state.messages.single;
      expect(sent.status, ChatMessageStatus.sent);
      expect(sent.id, pending.id);
      expect(sent.senderId, me);
    });

    test('shows it in the conversation list without reloading it', () async {
      repository.conversations = [
        ChatConversation.fromJson({
          'participantId': peer,
          'participantName': 'Dara',
          'lastMessage': {
            'id': 'm0',
            'senderId': peer,
            'ciphertext': 'sealed:Still for sale?',
            'nonce': 'nonce',
            'createdAt': '2026-01-01T10:00:00.000Z',
          },
        }),
      ];
      // Lets the reload that opening the chat started finish first.
      await conversations.refresh();
      await settle();
      expect(
        conversations.state.value!.items.single.lastMessage,
        'Still for sale?',
      );
      repository.conversationRequests = 0;

      await chat.sendMessage('Yes, come by at 5');

      expect(repository.conversationRequests, 0);
      final listed = conversations.state.value!.items.single;
      expect(listed.lastMessage, 'Yes, come by at 5');
      expect(listed.lastMessageId, chat.state.messages.last.id);
    });

    test('sends ciphertext, never the plain text', () async {
      await chat.sendMessage('my address is 12 Main St');

      final wire = socket.sent.single;
      expect(wire.recipientId, peer);
      expect(wire.ciphertext, 'sealed:my address is 12 Main St');
    });

    test('uses a UUID the server accepts as the message id', () async {
      await chat.sendMessage('hello');

      expect(
        socket.sent.single.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('marks the message failed and says why', () async {
      socket.sendError = const ChatSendException(ChatSendProblem.noConnection);

      await chat.sendMessage('hello');

      expect(chat.state.messages.single.status, ChatMessageStatus.failed);
      expect(chat.state.sendError, ChatSendProblem.noConnection);
    });

    test('reports an encoding failure without sending partial data', () async {
      cipher.encryptError = const FormatException('invalid attachment');

      await chat.sendMessage('hello');

      expect(socket.sent, isEmpty);
      expect(chat.state.messages.single.status, ChatMessageStatus.failed);
      expect(chat.state.sendError, ChatSendProblem.failed);
    });

    test('retries a failed message under the same id', () async {
      socket.sendError = const ChatSendException(ChatSendProblem.noConnection);
      await chat.sendMessage('hello');
      final failedId = chat.state.messages.single.id;

      socket.sendError = null;
      await chat.retry(failedId);

      expect(socket.sent.map((m) => m.id), [failedId, failedId]);
      expect(chat.state.messages.single.status, ChatMessageStatus.sent);
      expect(chat.state.sendError, isNull);
    });

    test(
      'does not duplicate a sent message when the server echoes it',
      () async {
        await chat.sendMessage('hello');

        socket.messages.add(socket.sent.single);
        await settle();

        expect(texts(), ['hello']);
      },
    );

    test('sends new messages without legacy setup', () async {
      await chat.sendMessage('hello');

      expect(texts(), ['hello']);
      expect(socket.sent, hasLength(1));
    });
  });

  group('reconnecting', () {
    test('loads what was missed, without duplicates', () async {
      repository.history = [encrypted('m1', 'first', from: peer)];
      await chat.open();

      repository.history = [
        encrypted('m1', 'first', from: peer),
        encrypted('m2', 'sent while offline', from: peer),
      ];
      socket.connections.add(null);
      await settle();

      expect(texts(), ['first', 'sent while offline']);
    });

    test('keeps a message that failed to send', () async {
      await chat.open();
      socket.sendError = const ChatSendException(ChatSendProblem.noConnection);
      await chat.sendMessage('unsent');

      repository.history = [encrypted('m1', 'from the server', from: peer)];
      socket.connections.add(null);
      await settle();

      expect(texts(), ['from the server', 'unsent']);
      expect(chat.state.messages.last.status, ChatMessageStatus.failed);
    });
  });

  test('stops listening when the screen closes', () async {
    final closing = ActiveChatNotifier(
      userId: me,
      participantId: peer,
      repository: repository,
      socketService: socket,
      cipher: cipher,
      attachments: attachments,
      conversations: conversations,
    );
    await closing.open();
    closing.dispose();

    socket.messages.add(encrypted('m1', 'hi', from: peer));
    socket.connections.add(null);
    await settle();
    // Reaching here without a "used after dispose" error is the assertion.
  });
}
