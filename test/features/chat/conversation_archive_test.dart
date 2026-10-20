import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/conversation_change.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/chat/providers/conversation_actions.dart';

import 'chat_fakes.dart';

ChatConversation _conversation(String participantId) {
  return ChatConversation.fromJson({
    'participantId': participantId,
    'participantName': 'Dara',
    'unreadCount': 0,
    'lastMessage': {
      'id': 'last-$participantId',
      'senderId': participantId,
      'ciphertext': 'sealed:Hello',
      'nonce': 'nonce',
      'createdAt': '2026-01-01T10:00:00.000Z',
    },
  });
}

void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  ConversationsNotifier list({bool archived = false}) {
    final notifier = ConversationsNotifier(
      repository: repository,
      socketService: socket,
      cipher: FakeCipher(),
      archived: archived,
    );
    addTearDown(notifier.dispose);
    return notifier;
  }

  List<String> ids(ConversationsNotifier notifier) =>
      notifier.state.value!.items.map((c) => c.participantId).toList();

  setUp(() {
    repository = FakeChatRepository();
    socket = FakeChatSocket();
  });

  group('the archive list', () {
    test('loads the archived conversations', () async {
      repository.conversations = [_conversation('main-1')];
      repository.archivedConversations = [_conversation(peer)];

      final archive = list(archived: true);
      await settle();

      expect(ids(archive), [peer]);
    });

    test(
      'lets go of a conversation when a new message arrives in it',
      () async {
        repository.archivedConversations = [_conversation(peer)];
        final archive = list(archived: true);
        await settle();

        socket.messages.add(encrypted('m1', 'Still for sale?', from: peer));
        await settle();

        expect(ids(archive), isEmpty);
      },
    );

    test('reloads when a conversation changes on another device', () async {
      final archive = list(archived: true);
      await settle();
      final requests = repository.conversationRequests;

      repository.archivedConversations = [_conversation(peer)];
      socket.conversationChanges.add(
        const ConversationChange(participantId: peer, historyCleared: false),
      );
      await settle();

      expect(repository.conversationRequests, requests + 1);
      expect(ids(archive), [peer]);
    });
  });

  group('ConversationActions', () {
    late ProviderContainer container;
    late ConversationsNotifier main;

    setUp(() async {
      repository.conversations = [_conversation(peer), _conversation('other')];
      container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repository),
          conversationsProvider.overrideWith(
            (ref) => ConversationsNotifier(
              repository: repository,
              socketService: socket,
              cipher: FakeCipher(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      main = container.read(conversationsProvider.notifier);
      await settle();
    });

    test('archiving takes the chat off the list at once, then asks the '
        'server', () async {
      final archiving = container
          .read(conversationActionsProvider)
          .archive(peer);

      expect(ids(main), ['other']);
      repository.conversations = [_conversation('other')];
      await archiving;

      expect(repository.conversationChanges, ['archive $peer']);
      expect(ids(main), ['other']);
    });

    test('a failed archive is reported and the chat comes back', () async {
      repository.changeError = Exception('offline');

      await expectLater(
        container.read(conversationActionsProvider).archive(peer),
        throwsException,
      );

      expect(ids(main), [peer, 'other']);
    });

    test('deleting for both people says so to the server', () async {
      await container
          .read(conversationActionsProvider)
          .delete(peer, forEveryone: true, fromArchive: false);

      expect(repository.conversationChanges, ['delete $peer forEveryone']);
    });

    test('deleting for me only says so too', () async {
      await container
          .read(conversationActionsProvider)
          .delete(peer, forEveryone: false, fromArchive: false);

      expect(repository.conversationChanges, ['delete $peer']);
    });
  });

  test(
    'an open chat empties when the other person deletes it for both',
    () async {
      final conversations = list();
      final chat = ActiveChatNotifier(
        userId: me,
        participantId: peer,
        repository: repository,
        socketService: socket,
        setupService: FakeSetupService(),
        cipher: FakeCipher(),
        attachments: FakeAttachmentService(),
        conversations: conversations,
      );
      addTearDown(chat.dispose);
      repository.history = [encrypted('m1', 'Hello', from: peer)];
      await chat.open(askPin: neverAskPin);
      expect(chat.state.messages, hasLength(1));

      repository.history = [];
      socket.conversationChanges.add(
        const ConversationChange(participantId: peer, historyCleared: true),
      );
      await settle();
      await settle();

      expect(chat.state.messages, isEmpty);
    },
  );
}
