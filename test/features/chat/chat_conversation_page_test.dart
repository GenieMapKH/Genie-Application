import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/message_cipher.dart';
import 'package:genie/features/chat/models/chat_participant.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

import 'chat_fakes.dart';

void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;
  late FakeSetupService setup;
  late FakeCipher cipher;
  late FakeAttachmentService attachments;

  setUp(() {
    repository = FakeChatRepository();
    socket = FakeChatSocket();
    setup = FakeSetupService();
    cipher = FakeCipher();
    attachments = FakeAttachmentService();
  });

  Future<void> openChat(
    WidgetTester tester, {
    String participantId = peer,
  }) async {
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
          e2eeSetupServiceProvider.overrideWithValue(setup),
          messageCipherProvider.overrideWith((ref, userId) => cipher),
          chatAttachmentServiceProvider.overrideWithValue(attachments),
        ],
        child: MaterialApp(
          home: ChatConversationPage(
            participantId: participantId,
            participantName: 'Dara',
          ),
        ),
      ),
    );
    // Profile, encryption setup, then the history.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  /// The side of the screen a message is shown on.
  Alignment sideOf(WidgetTester tester, String text) {
    final align = tester.widget<Align>(
      find.ancestor(of: find.text(text), matching: find.byType(Align)).first,
    );
    return align.alignment as Alignment;
  }

  testWidgets('my messages are on the right, theirs on the left', (
    tester,
  ) async {
    repository.history = [
      encrypted('m1', 'Is the villa still available?', from: me),
      encrypted('m2', 'Yes, it is', from: peer),
    ];

    await openChat(tester);

    expect(
      sideOf(tester, 'Is the villa still available?'),
      Alignment.centerRight,
    );
    expect(sideOf(tester, 'Yes, it is'), Alignment.centerLeft);
  });

  testWidgets('a message I send appears once, on the right', (tester) async {
    await openChat(tester);

    await tester.enterText(find.byType(TextField), 'Hello there');
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();
    await tester.pump();

    expect(find.text('Hello there'), findsOneWidget);
    expect(sideOf(tester, 'Hello there'), Alignment.centerRight);
    expect(find.text('SendingÃ¢â‚¬Â¦'), findsNothing);
  });

  testWidgets('an incoming message appears on the left', (tester) async {
    await openChat(tester);

    socket.messages.add(encrypted('m1', 'Are you free today?', from: peer));
    await tester.pump();
    await tester.pump();

    expect(sideOf(tester, 'Are you free today?'), Alignment.centerLeft);
  });

  testWidgets('a message that failed to send says so and can be retried', (
    tester,
  ) async {
    await openChat(tester);
    socket.sendError = const ChatSendException('Could not reach the server.');

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();
    await tester.pump();

    expect(find.text('Not sent. Tap to retry.'), findsOneWidget);
    expect(find.text('Could not reach the server.'), findsOneWidget);

    socket.sendError = null;
    await tester.tap(find.text('Hello'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Not sent. Tap to retry.'), findsNothing);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('explains a wrong PIN and offers another try', (tester) async {
    setup.result = E2eeSetupResult.wrongPin;

    await openChat(tester);

    expect(
      find.text(
        'Incorrect PIN. After 5 wrong tries the backup locks for a while.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);

    setup.result = E2eeSetupResult.ready;
    await tester.tap(find.text('Try again'));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('the header shows whether the other person is online', (
    tester,
  ) async {
    socket.presenceOf = (userId) => ChatPresence(userId: userId, online: true);

    await openChat(tester);

    expect(find.text('Dara'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);

    socket.presence.add(
      ChatPresence(
        userId: peer,
        online: false,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Online'), findsNothing);
    expect(find.text('Last seen 3 min ago'), findsOneWidget);
  });

  testWidgets('tapping the header shows their profile and security code', (
    tester,
  ) async {
    repository.participant = ChatParticipantProfile(
      id: peer,
      username: 'Dara Sok',
      memberSince: DateTime.utc(2025, 3, 10),
    );
    await openChat(tester);

    await tester.tap(find.text('Dara'));
    await tester.pumpAndSettle();

    expect(find.text('Dara Sok'), findsOneWidget);
    expect(find.text('Member since March 2025'), findsOneWidget);
    expect(find.text('11111 22222 33333 44444 55555 66666'), findsOneWidget);
  });

  testWidgets('a changed security key blocks sending until it is accepted', (
    tester,
  ) async {
    cipher.peerKeyStatus = PeerKeyStatus.changed;

    await openChat(tester);

    expect(find.text("Dara's security key has changed"), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Accept new key'));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    expect(find.text("Dara's security key has changed"), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('a chat with your own account cannot be opened', (tester) async {
    await openChat(tester, participantId: me);

    expect(find.text('This is your own account.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(setup.runs, 0);
  });
}
