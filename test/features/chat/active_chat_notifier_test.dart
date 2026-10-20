import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';

import 'chat_fakes.dart';

void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;
  late FakeSetupService setup;
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
    setup = FakeSetupService();
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
      setupService: setup,
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

      await chat.open(askPin: neverAskPin);

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

      await chat.open(askPin: neverAskPin);

      expect(texts(), [ActiveChatNotifier.undecryptableText]);
    });

    for (final result in [
      E2eeSetupResult.pinNotSet,
      E2eeSetupResult.lockedWithPassword,
      E2eeSetupResult.cancelled,
      E2eeSetupResult.rateLimited,
      E2eeSetupResult.failed,
    ]) {
      test(
        'stays closed when encryption setup ends as ${result.name}',
        () async {
          setup.result = result;

          await chat.open(askPin: neverAskPin);

          expect(chat.state.status, ActiveChatStatus.unavailable);
          expect(chat.state.setupResult, result);
          expect(repository.historyRequests, 0);
        },
      );
    }

    test('can be retried after a failure', () async {
      setup.result = E2eeSetupResult.rateLimited;
      await chat.open(askPin: neverAskPin);

      setup.result = E2eeSetupResult.ready;
      repository.history = [encrypted('m1', 'hello', from: peer)];
      await chat.open(askPin: neverAskPin);

      expect(chat.state.status, ActiveChatStatus.ready);
      expect(texts(), ['hello']);
    });
  });

  group('receiving', () {
    test(
      'adds a live message from the other person and marks it read',
      () async {
        await chat.open(askPin: neverAskPin);
        repository.markedRead.clear();

        socket.messages.add(encrypted('m1', 'hi there', from: peer));
        await settle();

        expect(texts(), ['hi there']);
        expect(repository.markedRead, [peer]);
      },
    );

    test('never shows the same message twice', () async {
      repository.history = [encrypted('m1', 'hi', from: peer)];
      await chat.open(askPin: neverAskPin);

      socket.messages.add(encrypted('m1', 'hi', from: peer));
      socket.messages.add(encrypted('m1', 'hi', from: peer));
      await settle();

      expect(texts(), ['hi']);
    });

    test('ignores messages that belong to another conversation', () async {
      await chat.open(askPin: neverAskPin);

      socket.messages.add(encrypted('m1', 'psst', from: 'someone-else'));
      await settle();

      expect(chat.state.messages, isEmpty);
    });

    test(
      'shows a message this user sent from another device as theirs',
      () async {
        await chat.open(askPin: neverAskPin);
        repository.markedRead.clear();

        socket.messages.add(encrypted('m1', 'sent from my tablet', from: me));
        await settle();

        expect(chat.state.messages.single.senderId, me);
        expect(repository.markedRead, isEmpty);
      },
    );

    test('keeps live messages in the order they arrived', () async {
      await chat.open(askPin: neverAskPin);

      for (final text in ['one', 'two', 'three']) {
        socket.messages.add(encrypted(text, text, from: peer));
      }
      await settle();

      expect(texts(), ['one', 'two', 'three']);
    });

    test('ignores live messages until encryption is ready', () async {
      setup.result = E2eeSetupResult.cancelled;
      await chat.open(askPin: neverAskPin);

      socket.messages.add(encrypted('m1', 'hi', from: peer));
      await settle();

      expect(chat.state.messages, isEmpty);
    });
  });

  group('sending', () {
    setUp(() => chat.open(askPin: neverAskPin));

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
      expect(conversations.state.value!.single.lastMessage, 'Still for sale?');
      repository.conversationRequests = 0;

      await chat.sendMessage('Yes, come by at 5');

      expect(repository.conversationRequests, 0);
      final listed = conversations.state.value!.single;
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

    test('explains when the other person has no keys yet', () async {
      cipher.encryptError = const ChatEncryptionException(
        ChatSendProblem.peerNotReady,
        'no keys',
      );

      await chat.sendMessage('hello');

      expect(socket.sent, isEmpty);
      expect(chat.state.messages.single.status, ChatMessageStatus.failed);
      expect(chat.state.sendError, ChatSendProblem.peerNotReady);
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

    test('does nothing while the chat is not open', () async {
      setup.result = E2eeSetupResult.cancelled;
      await chat.open(askPin: neverAskPin);

      await chat.sendMessage('hello');

      expect(chat.state.messages, isEmpty);
      expect(socket.sent, isEmpty);
    });
  });

  group("when the other person's key changed", () {
    EncryptedMessage unreadable(String id) => EncryptedMessage(
      id: id,
      senderId: peer,
      recipientId: me,
      ciphertext: 'made-with-a-new-key',
      nonce: 'nonce',
      createdAt: DateTime.utc(2026),
    );

    test('opening the chat says so and nothing can be sent', () async {
      cipher.peerKeyStatus = PeerKeyStatus.changed;

      await chat.open(askPin: neverAskPin);
      await chat.sendMessage('my bank details');

      expect(chat.state.status, ActiveChatStatus.ready);
      expect(chat.state.peerKeyChanged, isTrue);
      expect(chat.state.messages, isEmpty);
      expect(socket.sent, isEmpty);
    });

    test('a change noticed while sending stops the message', () async {
      await chat.open(askPin: neverAskPin);
      cipher.peerKeyStatus = PeerKeyStatus.changed;

      await chat.sendMessage('my bank details');

      expect(socket.sent, isEmpty);
      expect(chat.state.peerKeyChanged, isTrue);
      expect(chat.state.messages.single.status, ChatMessageStatus.failed);
    });

    test('an unreadable incoming message triggers a key check', () async {
      await chat.open(askPin: neverAskPin);
      cipher.peerKeyStatus = PeerKeyStatus.changed;
      cipher.keyChecks = 0;

      // A burst of them must not turn into a burst of requests.
      await Future<void>.delayed(const Duration(milliseconds: 1));
      socket.messages.add(unreadable('m1'));
      socket.messages.add(unreadable('m2'));
      await settle();

      expect(texts(), [
        ActiveChatNotifier.undecryptableText,
        ActiveChatNotifier.undecryptableText,
      ]);
      expect(cipher.keyChecks, lessThanOrEqualTo(1));
    });

    test('accepting the new key reloads the chat and allows sending', () async {
      cipher.peerKeyStatus = PeerKeyStatus.changed;
      await chat.open(askPin: neverAskPin);
      repository.history = [encrypted('m1', 'hi, new phone', from: peer)];

      await chat.acceptNewPeerKey();
      await chat.sendMessage('welcome back');

      expect(cipher.acceptedKeys, 1);
      expect(chat.state.peerKeyChanged, isFalse);
      expect(texts(), ['hi, new phone', 'welcome back']);
      expect(socket.sent, hasLength(1));
    });
  });

  group('reconnecting', () {
    test('loads what was missed, without duplicates', () async {
      repository.history = [encrypted('m1', 'first', from: peer)];
      await chat.open(askPin: neverAskPin);

      repository.history = [
        encrypted('m1', 'first', from: peer),
        encrypted('m2', 'sent while offline', from: peer),
      ];
      socket.connections.add(null);
      await settle();

      expect(texts(), ['first', 'sent while offline']);
    });

    test('keeps a message that failed to send', () async {
      await chat.open(askPin: neverAskPin);
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
      setupService: setup,
      cipher: cipher,
      attachments: attachments,
      conversations: conversations,
    );
    await closing.open(askPin: neverAskPin);
    closing.dispose();

    socket.messages.add(encrypted('m1', 'hi', from: peer));
    socket.connections.add(null);
    await settle();
    // Reaching here without a "used after dispose" error is the assertion.
  });
}
