import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/message_deletion.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

import 'chat_fakes.dart';

/// Swiping, holding and the reply / edit / delete flows on the chat screen.
void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;
  late FakeCipher cipher;

  setUp(() {
    repository = FakeChatRepository();
    socket = FakeChatSocket();
    cipher = FakeCipher();
  });

  EncryptedMessage recent(
    String id,
    String text, {
    required String from,
    EncryptedMessage? replyTo,
    DateTime? editedAt,
  }) {
    return EncryptedMessage(
      id: id,
      senderId: from,
      recipientId: from == me ? peer : me,
      ciphertext: 'sealed:$text',
      nonce: 'nonce',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      replyTo: replyTo,
      editedAt: editedAt,
    );
  }

  MessageDeletion deletion(String messageId) =>
      MessageDeletion(messageId: messageId, participantId: peer);

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
          chatAttachmentServiceProvider.overrideWithValue(
            FakeAttachmentService(),
          ),
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

  Future<void> swipe(WidgetTester tester, String text, double dx) async {
    await tester.drag(find.text(text), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  Future<void> hold(WidgetTester tester, String text) async {
    await tester.longPress(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String text, {IconData? icon}) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.byIcon(icon ?? Icons.send_outlined));
    await tester.pump();
    await tester.pump();
  }

  group('swiping to reply', () {
    testWidgets("their message to the right replies to it", (tester) async {
      repository.history = [recent('m1', 'Is it available?', from: peer)];
      await openChat(tester);

      await swipe(tester, 'Is it available?', 100);

      expect(find.text('Replying to Dara'), findsOneWidget);
      await send(tester, 'Yes');
      expect(socket.sentReplyIds.values, ['m1']);
      expect(find.text('Replying to Dara'), findsNothing);
      // The reply shows the message it quotes above it.
      expect(find.text('Is it available?'), findsNWidgets(2));
    });

    testWidgets('my own message to the left replies to it', (tester) async {
      repository.history = [recent('m1', 'See you at 5', from: me)];
      await openChat(tester);

      await swipe(tester, 'See you at 5', -100);

      expect(find.text('Replying to You'), findsOneWidget);
    });

    testWidgets('the wrong way, or too short, does nothing', (tester) async {
      repository.history = [
        recent('m1', 'Hi', from: peer),
        recent('m2', 'Hello', from: me),
      ];
      await openChat(tester);

      await swipe(tester, 'Hi', -100);
      await swipe(tester, 'Hello', 100);
      await swipe(tester, 'Hi', 20);

      expect(find.textContaining('Replying to'), findsNothing);
    });

    testWidgets('the reply can be cancelled', (tester) async {
      repository.history = [recent('m1', 'Hi', from: peer)];
      await openChat(tester);
      await swipe(tester, 'Hi', 100);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await send(tester, 'New topic');

      expect(socket.sentReplyIds, isEmpty);
    });
  });

  group('holding a message', () {
    testWidgets('offers reply, copy, edit and delete for my recent text', (
      tester,
    ) async {
      repository.history = [recent('m1', 'See you at 5', from: me)];
      await openChat(tester);

      await hold(tester, 'See you at 5');

      for (final label in ['Reply', 'Copy', 'Edit', 'Delete']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets("offers no edit for their message, or mine after an hour", (
      tester,
    ) async {
      repository.history = [
        recent('m1', 'Hi', from: peer),
        encrypted('m2', 'Old one', from: me),
      ];
      await openChat(tester);

      await hold(tester, 'Hi');
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Reply'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await hold(tester, 'Old one');
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('edit puts the text in the field and saves the new text', (
      tester,
    ) async {
      repository.history = [recent('m1', 'See you at 5', from: me)];
      await openChat(tester);

      await hold(tester, 'See you at 5');
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Editing message'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'See you at 5');

      await send(tester, 'See you at 6', icon: Icons.check);

      expect(repository.messageChanges, ['edit m1 sealed:See you at 6']);
      expect(find.text('See you at 6'), findsOneWidget);
      expect(find.text('Edited'), findsOneWidget);
      expect(find.text('Editing message'), findsNothing);
    });

    testWidgets('copy puts the text on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      repository.history = [recent('m1', 'Street 63', from: peer)];
      await openChat(tester);

      await hold(tester, 'Street 63');
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(copied, 'Street 63');
      expect(find.text('Copied'), findsOneWidget);
    });
  });

  group('deleting', () {
    Future<void> chooseDelete(WidgetTester tester, String text) async {
      await hold(tester, text);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    }

    testWidgets('my message: for everyone, and nothing is left', (
      tester,
    ) async {
      repository.history = [recent('m1', 'Oops, wrong chat', from: me)];
      await openChat(tester);

      await chooseDelete(tester, 'Oops, wrong chat');
      expect(find.text('Delete for me'), findsOneWidget);
      await tester.tap(find.text('Delete for everyone'));
      await tester.pumpAndSettle();

      expect(repository.messageChanges, ['delete m1 forEveryone']);
      expect(find.text('Oops, wrong chat'), findsNothing);
    });

    testWidgets('my message: for me only', (tester) async {
      repository.history = [recent('m1', 'Hello', from: me)];
      await openChat(tester);

      await chooseDelete(tester, 'Hello');
      await tester.tap(find.text('Delete for me'));
      await tester.pumpAndSettle();

      expect(repository.messageChanges, ['delete m1']);
      expect(find.text('Hello'), findsNothing);
    });

    testWidgets('their message can only be deleted for me', (tester) async {
      repository.history = [recent('m1', 'Spam', from: peer)];
      await openChat(tester);

      await chooseDelete(tester, 'Spam');

      expect(find.text('Delete for everyone'), findsNothing);
      await tester.tap(find.text('Delete for me'));
      await tester.pumpAndSettle();
      expect(repository.messageChanges, ['delete m1']);
    });

    testWidgets('cancelling deletes nothing', (tester) async {
      repository.history = [recent('m1', 'Hello', from: me)];
      await openChat(tester);

      await chooseDelete(tester, 'Hello');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.messageChanges, isEmpty);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('a reply stops quoting a message deleted for everyone', (
      tester,
    ) async {
      final quoted = recent('m1', 'Wrong address', from: peer);
      cipher.sealedReplies['m2'] = 'm1';
      repository.history = [
        quoted,
        recent('m2', 'Which one?', from: me, replyTo: quoted),
      ];
      await openChat(tester);
      expect(find.text('Wrong address'), findsNWidgets(2));

      socket.deletedMessages.add(deletion('m1'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Wrong address'), findsNothing);
      expect(find.text('Which one?'), findsOneWidget);
    });

    testWidgets('replying stops when the message is deleted meanwhile', (
      tester,
    ) async {
      repository.history = [recent('m1', 'Hi', from: peer)];
      await openChat(tester);
      await swipe(tester, 'Hi', 100);

      socket.deletedMessages.add(deletion('m1'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Replying to'), findsNothing);
    });
  });

  testWidgets('an edited message says so', (tester) async {
    repository.history = [
      recent('m1', 'Now 6pm', from: peer, editedAt: DateTime.now()),
    ];
    await openChat(tester);

    expect(find.text('Edited'), findsOneWidget);
  });
}
