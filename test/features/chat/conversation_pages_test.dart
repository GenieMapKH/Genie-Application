import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_repository.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';

import 'chat_fakes.dart';

ChatConversation _conversation(String participantId, {int unread = 0}) {
  return ChatConversation.fromJson({
    'participantId': participantId,
    'participantName': participantId,
    'unreadCount': unread,
    'lastMessage': {
      'id': 'last-$participantId',
      'senderId': participantId,
      'ciphertext': 'sealed:hello',
      'nonce': 'nonce',
      'createdAt': '2026-01-01T10:00:00.000Z',
    },
  });
}

/// [count] conversations, `user-0` the most recent; each holds one unread
/// message.
List<ChatConversation> _many(int count) => [
  for (var i = 0; i < count; i++) _conversation('user-$i', unread: 1),
];

void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ConversationsNotifier build() {
    final notifier = ConversationsNotifier(
      repository: repository,
      socketService: socket,
      cipher: FakeCipher(),
    );
    addTearDown(notifier.dispose);
    return notifier;
  }

  setUp(() {
    repository = FakeChatRepository();
    socket = FakeChatSocket();
  });

  List<String> shown(ConversationsNotifier notifier) => [
    for (final c in notifier.state.value!.items) c.participantId,
  ];

  test('loads a page, then the next, without repeats', () async {
    repository.conversations = _many(45);
    final notifier = build();
    await settle();

    expect(shown(notifier), hasLength(ChatRepository.conversationPageSize));
    expect(notifier.state.value!.page.hasMore, isTrue);

    await notifier.loadMore();

    expect(shown(notifier), [for (var i = 0; i < 45; i++) 'user-$i']);
    expect(notifier.state.value!.page.hasMore, isFalse);
    expect(repository.conversationCursors, [null, '30']);
  });

  test('a conversation already shown is not added again', () async {
    repository.conversations = _many(45);
    final notifier = build();
    await settle();
    // user-29 moved onto the next page on the server meanwhile.
    repository.conversations = [_conversation('new'), ..._many(45)];

    await notifier.loadMore();

    final ids = shown(notifier);
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('a reload reads back as many as are shown', () async {
    repository.conversations = _many(45);
    final notifier = build();
    await settle();
    await notifier.loadMore();

    await notifier.refresh();

    expect(shown(notifier), hasLength(45));
  });

  group('the unread total', () {
    test('counts the whole list, not only what is loaded', () async {
      repository.conversations = _many(45);
      final notifier = build();
      await settle();

      expect(notifier.state.value!.unreadTotal, 45);
    });

    test('goes up with a message from the other person', () async {
      repository.conversations = _many(3);
      final notifier = build();
      await settle();

      socket.messages.add(encrypted('m2', 'hi', from: 'user-1'));
      await settle();

      expect(notifier.state.value!.unreadTotal, 4);
    });

    test('goes down by what a read conversation held', () async {
      repository.conversations = [
        _conversation('user-0', unread: 3),
        _conversation('user-1', unread: 2),
      ];
      final notifier = build();
      await settle();

      await notifier.markAsRead('user-0');

      expect(notifier.state.value!.unreadTotal, 2);
    });

    test('is read again after reading a conversation not loaded', () async {
      repository.conversations = _many(45);
      final notifier = build();
      await settle();
      // Read on the server: user-40 is past the loaded page.
      repository.conversations = [
        for (final c in _many(45))
          c.participantId == 'user-40' ? c.copyWith(unreadCount: 0) : c,
      ];

      await notifier.markAsRead('user-40');

      expect(notifier.state.value!.unreadTotal, 44);
    });

    test('goes down by what a removed conversation held', () async {
      repository.conversations = [
        _conversation('user-0', unread: 3),
        _conversation('user-1', unread: 2),
      ];
      final notifier = build();
      await settle();

      notifier.removeLocally('user-1');

      expect(notifier.state.value!.unreadTotal, 3);
    });
  });
}
