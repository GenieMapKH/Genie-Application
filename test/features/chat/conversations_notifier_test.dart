import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/models/chat_models.dart';
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
}
