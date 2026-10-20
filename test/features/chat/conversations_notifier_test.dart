import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/message_deletion.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';

import 'chat_fakes.dart';

ChatConversation _conversation(
  String participantId, {
  int unread = 0,
  String? ciphertext = 'sealed:See you at 5',
}) {
  return ChatConversation.fromJson({
    'participantId': participantId,
    'participantName': 'Dara',
    'unreadCount': unread,
    if (ciphertext != null)
      'lastMessage': {
        'id': 'last-$participantId',
        'senderId': participantId,
        'ciphertext': ciphertext,
        'nonce': 'nonce',
        'createdAt': '2026-01-01T10:00:00.000Z',
      },
  });
}

void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ConversationsNotifier build({bool signedIn = true}) {
    final notifier = ConversationsNotifier(
      repository: repository,
      socketService: socket,
      cipher: signedIn ? FakeCipher() : null,
    );
    addTearDown(notifier.dispose);
    return notifier;
  }

  setUp(() {
    repository = FakeChatRepository();
    socket = FakeChatSocket();
  });

  test('loads the list with decrypted previews', () async {
    repository.conversations = [_conversation(peer, unread: 2)];

    final notifier = build();
    await settle();

    final conversation = notifier.state.value!.single;
    expect(conversation.lastMessage, 'See you at 5');
    expect(conversation.unreadCount, 2);
  });

  test('keeps the placeholder when a preview cannot be decrypted', () async {
    repository.conversations = [
      _conversation(peer, ciphertext: 'made-with-other-keys'),
    ];

    final notifier = build();
    await settle();

    expect(
      notifier.state.value!.single.lastMessage,
      ChatConversation.encryptedPreview,
    );
  });

  test('a guest has no conversations and asks the server for none', () async {
    final notifier = build(signedIn: false);
    await settle();

    expect(notifier.state.value, isEmpty);
    expect(repository.conversationRequests, 0);
  });

  test('stays loading while it is not known who is signed in', () async {
    final notifier = ConversationsNotifier(
      repository: repository,
      socketService: socket,
      cipher: null,
      signInPending: true,
    );
    addTearDown(notifier.dispose);

    expect(notifier.state.isLoading, isTrue);
  });

  test('a burst of messages reloads the list once, not once each', () async {
    final notifier = build();
    await settle();
    repository.conversationRequests = 0;

    repository.gate = Completer<void>();
    for (var i = 0; i < 20; i++) {
      socket.messages.add(encrypted('m$i', 'hi', from: peer));
    }
    await settle();
    repository.gate!.complete();
    await settle();
    await settle();

    // One for the first message, one more for everything that followed.
    expect(repository.conversationRequests, 2);
    expect(notifier.state.hasValue, isTrue);
  });

  test('reloads when the connection comes back', () async {
    build();
    await settle();
    repository.conversationRequests = 0;

    socket.connections.add(null);
    await settle();

    expect(repository.conversationRequests, 1);
  });

  test('a failed reload keeps the list on screen', () async {
    repository.conversations = [_conversation(peer)];
    final notifier = build();
    await settle();

    repository.conversationsError = Exception('offline');
    await notifier.refresh();

    expect(notifier.state.hasError, isFalse);
    expect(notifier.state.value, hasLength(1));
  });

  test('a failed first load reports the error', () async {
    repository.conversationsError = Exception('offline');

    final notifier = build();
    await settle();

    expect(notifier.state.hasError, isTrue);
  });

  test('marking a chat read clears only its unread count', () async {
    repository.conversations = [
      _conversation(peer, unread: 3),
      _conversation('user-other', unread: 1),
    ];
    final notifier = build();
    await settle();

    await notifier.markAsRead(peer);

    expect(repository.markedRead, [peer]);
    expect(notifier.state.value!.map((c) => c.unreadCount), [0, 1]);
  });

  group('a new message', () {
    test(
      'updates its conversation in place, without reloading the list',
      () async {
        repository.conversations = [
          _conversation('user-other'),
          _conversation(peer, unread: 1),
        ];
        final notifier = build();
        await settle();
        repository.conversationRequests = 0;

        socket.messages.add(
          encrypted('m2', 'Is it still for sale?', from: peer),
        );
        await settle();

        expect(repository.conversationRequests, 0);
        final top = notifier.state.value!.first;
        expect(top.participantId, peer, reason: 'moved to the top');
        expect(top.lastMessage, 'Is it still for sale?');
        expect(top.unreadCount, 2);
      },
    );

    test('read in the open chat ends up unread by none', () async {
      repository.conversations = [_conversation(peer)];
      final notifier = build();
      await settle();

      socket.messages.add(encrypted('m2', 'hi', from: peer));
      // The open chat marks each message read once it has shown it, which
      // can be before the list has decrypted its preview.
      await Future<void>.microtask(() {});
      unawaited(notifier.markAsRead(peer));
      await settle();

      expect(notifier.state.value!.single.unreadCount, 0);
    });

    test('sent from my other device is not unread', () async {
      repository.conversations = [_conversation(peer)];
      final notifier = build();
      await settle();

      socket.messages.add(encrypted('m2', 'On my way', from: me));
      await settle();

      final conversation = notifier.state.value!.single;
      expect(conversation.lastMessage, 'On my way');
      expect(conversation.unreadCount, 0);
    });

    test('from someone not in the list yet loads the list again', () async {
      final notifier = build();
      await settle();
      repository.conversationRequests = 0;
      repository.conversations = [_conversation(peer)];

      socket.messages.add(encrypted('m2', 'Hello', from: peer));
      await settle();
      await settle();

      expect(repository.conversationRequests, 1);
      expect(notifier.state.value, hasLength(1));
    });
  });

  group('a message I sent from this device', () {
    test('moves its conversation to the top, without reloading', () async {
      repository.conversations = [
        _conversation('user-other'),
        _conversation(peer, unread: 0),
      ];
      final notifier = build();
      await settle();
      repository.conversationRequests = 0;

      notifier.recordSent(encrypted('m2', 'Deal', from: me), preview: 'Deal');

      expect(repository.conversationRequests, 0);
      final top = notifier.state.value!.first;
      expect(top.participantId, peer);
      expect(top.lastMessage, 'Deal');
      expect(top.lastMessageId, 'm2');
      expect(top.unreadCount, 0);
    });

    test('to someone not in the list loads the list', () async {
      final notifier = build();
      await settle();
      repository.conversationRequests = 0;
      repository.conversations = [_conversation(peer)];

      notifier.recordSent(encrypted('m2', 'Hi', from: me), preview: 'Hi');
      await settle();

      expect(repository.conversationRequests, 1);
      expect(notifier.state.value, hasLength(1));
    });
  });

  group('an edit', () {
    test(
      'of the last message changes its preview, without reloading',
      () async {
        repository.conversations = [_conversation(peer)];
        final notifier = build();
        await settle();
        repository.conversationRequests = 0;

        socket.editedMessages.add(
          EncryptedMessage(
            id: 'last-$peer',
            senderId: peer,
            recipientId: me,
            ciphertext: 'sealed:See you at 6',
            nonce: 'nonce-2',
            createdAt: DateTime.utc(2026),
          ),
        );
        await settle();

        expect(repository.conversationRequests, 0);
        expect(notifier.state.value!.single.lastMessage, 'See you at 6');
      },
    );

    test('of an older message changes nothing', () async {
      repository.conversations = [_conversation(peer)];
      final notifier = build();
      await settle();
      repository.conversationRequests = 0;

      socket.editedMessages.add(encrypted('older', 'typo fixed', from: peer));
      await settle();

      expect(repository.conversationRequests, 0);
      expect(notifier.state.value!.single.lastMessage, 'See you at 5');
    });
  });

  group('a deletion', () {
    test(
      'of the last message reloads: only the server knows the one before',
      () async {
        repository.conversations = [_conversation(peer)];
        build();
        await settle();
        repository.conversationRequests = 0;

        socket.deletedMessages.add(
          MessageDeletion(messageId: 'last-$peer', participantId: peer),
        );
        await settle();

        expect(repository.conversationRequests, 1);
      },
    );

    test('of an older message in a read chat changes nothing', () async {
      repository.conversations = [_conversation(peer)];
      build();
      await settle();
      repository.conversationRequests = 0;

      socket.deletedMessages.add(
        const MessageDeletion(messageId: 'older', participantId: peer),
      );
      await settle();

      expect(repository.conversationRequests, 0);
    });

    test('in a chat with unread messages reloads its count', () async {
      repository.conversations = [_conversation(peer, unread: 2)];
      build();
      await settle();
      repository.conversationRequests = 0;

      socket.deletedMessages.add(
        const MessageDeletion(messageId: 'older', participantId: peer),
      );
      await settle();

      expect(repository.conversationRequests, 1);
    });
  });

  test('reloading does not open previews again', () async {
    final cipher = FakeCipher();
    repository.conversations = [
      _conversation(peer),
      _conversation('user-other'),
    ];
    final notifier = ConversationsNotifier(
      repository: repository,
      socketService: socket,
      cipher: cipher,
    );
    addTearDown(notifier.dispose);
    await settle();
    expect(cipher.decrypts, 2);

    await notifier.refresh();

    expect(cipher.decrypts, 2);
    expect(notifier.state.value!.map((c) => c.lastMessage), [
      'See you at 5',
      'See you at 5',
    ]);
  });
}
