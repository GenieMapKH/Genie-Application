import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/keys/message_cipher.dart';
import 'package:genie/features/chat/models/chat_participant.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/safety/data/models/block_status.dart';
import 'package:genie/features/safety/presentation/view_models/block_providers.dart';

import 'package:genie/features/chat/models/chat_listing.dart';

import '../../support/test_app.dart';
import '../safety/fake_block_repository.dart';

import 'chat_fakes.dart';

void main() {
  late FakeChatRepository repository;
  late FakeChatSocket socket;
  late FakeSetupService setup;
  late FakeCipher cipher;
  late FakeAttachmentService attachments;
  late FakeBlockRepository blocks;

  setUp(() {
    repository = FakeChatRepository();
    socket = FakeChatSocket();
    setup = FakeSetupService();
    cipher = FakeCipher();
    attachments = FakeAttachmentService();
    blocks = FakeBlockRepository();
  });

  Future<void> openChat(
    WidgetTester tester, {
    String participantId = peer,
    ChatListing? listingToOffer,
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
          blockRepositoryProvider.overrideWithValue(blocks),
          signedInOverride(),
        ],
        child: MaterialApp(
          home: ChatConversationPage(
            participantId: participantId,
            participantName: 'Dara',
            listingToOffer: listingToOffer,
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
    socket.sendError = const ChatSendException(ChatSendProblem.noConnection);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();
    await tester.pump();

    expect(find.text('Not sent. Tap to retry.'), findsOneWidget);
    expect(
      find.text('Could not reach the server. Check your connection.'),
      findsOneWidget,
    );

    socket.sendError = null;
    await tester.tap(find.text('Hello'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Not sent. Tap to retry.'), findsNothing);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('a closed PIN prompt says chat is locked and offers the PIN', (
    tester,
  ) async {
    setup.result = E2eeSetupResult.cancelled;

    await openChat(tester);

    expect(find.text('Chats are locked on this phone'), findsOneWidget);
    // Someone who cannot remember it is told where the way back is.
    expect(find.textContaining('Forgot chat PIN'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    setup.result = E2eeSetupResult.ready;
    await tester.tap(find.text('Enter PIN'));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    expect(setup.runs, 2);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('too many wrong PINs is shown as a lock, not a broken chat', (
    tester,
  ) async {
    setup.result = E2eeSetupResult.rateLimited;

    await openChat(tester);

    expect(find.text('Too many wrong PINs'), findsOneWidget);
    expect(find.byIcon(Icons.lock_clock_outlined), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('an account without a chat PIN is sent to create one', (
    tester,
  ) async {
    setup.result = E2eeSetupResult.pinNotSet;

    await openChat(tester);

    expect(find.text('Create your chat PIN'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Create PIN'));
    await tester.pumpAndSettle();

    // The setup screen, with the six PIN boxes.
    expect(find.text('Type the same 6 digits again.'), findsNothing);
    expect(
      find.textContaining('This 6-digit PIN brings them back'),
      findsOneWidget,
    );
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

    await tester.tap(find.text('Security code'));
    await tester.pumpAndSettle();
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

  group('blocked', () {
    testWidgets('the blocker sees why the bar is gone, and can unblock', (
      tester,
    ) async {
      blocks.status = const BlockStatus(isBlocked: true, canMessage: false);

      await openChat(tester);

      expect(
        find.text("You blocked Dara. They can't message or call you."),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, 'Unblock'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Unblock').last);
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(blocks.calls, contains('unblock $peer'));
      expect(find.byType(TextField), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the person blocked is only told they cannot reply', (
      tester,
    ) async {
      blocks.status = const BlockStatus(isBlocked: false, canMessage: false);

      await openChat(tester);

      expect(
        find.text("You can't reply to this conversation."),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Unblock'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a message refused for a block asks again and hides the bar', (
      tester,
    ) async {
      await openChat(tester);
      blocks.status = const BlockStatus(isBlocked: false, canMessage: false);
      socket.sendError = const ChatSendException(ChatSendProblem.blocked);

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.send_outlined));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.text("You can't message this person."), findsOneWidget);
      expect(
        find.text("You can't reply to this conversation."),
        findsOneWidget,
      );
      expect(blocks.calls.where((c) => c == 'status $peer'), hasLength(2));
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('opened from a listing', () {
    const listing = ChatListing(
      id: 'p-1',
      title: 'Villa near Riverside',
      price: r'$ 120,000',
    );

    testWidgets('offers the listing, and sends it as a card', (tester) async {
      await openChat(tester, listingToOffer: listing);

      expect(find.text('Asking about this listing?'), findsOneWidget);
      expect(find.text('Villa near Riverside'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      // Sealed with the card, and a text for apps without cards.
      final sentId = cipher.sealedListings.keys.single;
      expect(cipher.sealedListings[sentId]?.id, 'p-1');
      expect(find.text('Asking about this listing?'), findsNothing);
      expect(find.text('View listing'), findsOneWidget);
      expect(
        find.text('\u{1F3E0} Villa near Riverside · \$ 120,000'),
        findsNothing,
      );
      expect(sideOf(tester, 'Villa near Riverside'), Alignment.centerRight);
    });

    testWidgets('can be closed without sending', (tester) async {
      await openChat(tester, listingToOffer: listing);

      await tester.tap(find.byTooltip('Not now'));
      await tester.pump();

      expect(find.text('Asking about this listing?'), findsNothing);
      expect(cipher.sealedListings, isEmpty);
    });

    testWidgets('a card the other person sent is shown as a card', (
      tester,
    ) async {
      repository.history = [encrypted('m1', listing.fallbackText, from: peer)];
      cipher.sealedListings['m1'] = listing;

      await openChat(tester);

      expect(find.text('View listing'), findsOneWidget);
      expect(sideOf(tester, 'Villa near Riverside'), Alignment.centerLeft);
    });
  });
}
