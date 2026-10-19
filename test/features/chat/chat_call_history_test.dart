import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/models/chat_call_entry.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_timeline.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_call_entry_tile.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

import 'chat_fakes.dart';

final _start = DateTime.utc(2026, 10, 19, 10);

ChatCallEntry call(
  String id, {
  String callerId = me,
  Duration after = Duration.zero,
  Duration? talked,
  String? endReason,
}) {
  final created = _start.add(after);
  final answered = talked == null
      ? null
      : created.add(const Duration(seconds: 4));
  return ChatCallEntry(
    id: id,
    callerId: callerId,
    createdAt: created,
    answeredAt: answered,
    endedAt: (answered ?? created.add(const Duration(seconds: 20))).add(
      talked ?? Duration.zero,
    ),
    endReason: endReason,
  );
}

void main() {
  group('how a call went', () {
    ChatCallOutcome outcome(ChatCallEntry entry, String viewer) =>
        entry.outcomeFor(viewer);

    test(
      'an answered call is completed, or lost when the connection dropped',
      () {
        final done = call(
          'c1',
          talked: const Duration(seconds: 154),
          endReason: 'ended',
        );
        final lost = call(
          'c2',
          talked: const Duration(seconds: 30),
          endReason: 'disconnected',
        );

        expect(outcome(done, me), ChatCallOutcome.completed);
        expect(outcome(done, peer), ChatCallOutcome.completed);
        expect(done.talkTime, const Duration(seconds: 154));
        expect(outcome(lost, me), ChatCallOutcome.lost);
      },
    );

    test(
      'a turned-down call reads differently for the caller and the callee',
      () {
        final declined = call('c1', endReason: 'declined');

        expect(outcome(declined, me), ChatCallOutcome.declinedByPeer);
        expect(outcome(declined, peer), ChatCallOutcome.declinedByMe);
      },
    );

    test(
      'an unanswered call is "no answer" for the caller and "missed" for the callee',
      () {
        final timedOut = call('c1', endReason: 'missed');

        expect(outcome(timedOut, me), ChatCallOutcome.noAnswer);
        expect(outcome(timedOut, peer), ChatCallOutcome.missed);
        expect(timedOut.talkTime, isNull);
      },
    );

    test('a caller who hangs up first cancelled it; the callee missed it', () {
      final cancelled = call('c1', endReason: 'cancelled');

      expect(outcome(cancelled, me), ChatCallOutcome.cancelled);
      expect(outcome(cancelled, peer), ChatCallOutcome.missed);
    });

    test('is read from the server\'s JSON, null times included', () {
      final entry = ChatCallEntry.fromJson({
        'id': 'c1',
        'callerId': peer,
        'createdAt': '2026-10-19T10:00:00.000Z',
        'answeredAt': null,
        'endedAt': '2026-10-19T10:00:45.000Z',
        'endReason': 'missed',
      });

      expect(entry.answeredAt, isNull);
      expect(entry.endedAt, DateTime.utc(2026, 10, 19, 10, 0, 45));
      expect(entry.outcomeFor(me), ChatCallOutcome.missed);
    });
  });

  group('the timeline', () {
    ChatMessage message(String id, Duration after) => ChatMessage(
      id: id,
      senderId: me,
      recipientId: peer,
      text: id,
      createdAt: _start.add(after),
    );

    test('puts calls among the messages by time', () {
      final items = mergeTimeline(
        [
          message('m1', Duration.zero),
          message('m2', const Duration(minutes: 10)),
        ],
        [call('c1', after: const Duration(minutes: 5))],
      );

      expect(items.map((item) => item.key), ['m1', 'call:c1', 'm2']);
    });

    test(
      'keeps messages in order, and lists a message before a call at the same moment',
      () {
        final items = mergeTimeline(
          [message('m1', Duration.zero), message('m2', Duration.zero)],
          [call('c1')],
        );

        expect(items.map((item) => item.key), ['m1', 'm2', 'call:c1']);
      },
    );

    test('is just the calls when nobody wrote anything', () {
      expect(mergeTimeline(const [], [call('c1')]), hasLength(1));
      expect(mergeTimeline(const [], const []), isEmpty);
    });
  });

  group('in the conversation', () {
    late FakeChatRepository repository;
    late FakeChatSocket socket;

    setUp(() {
      repository = FakeChatRepository();
      socket = FakeChatSocket();
    });

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
            messageCipherProvider.overrideWith((ref, userId) => FakeCipher()),
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

    testWidgets('shows how each call went, even with no messages', (
      tester,
    ) async {
      repository.callHistory = [
        call('c1', talked: const Duration(seconds: 154), endReason: 'ended'),
        call(
          'c2',
          callerId: peer,
          after: const Duration(minutes: 5),
          endReason: 'missed',
        ),
        call('c3', after: const Duration(minutes: 9), endReason: 'declined'),
      ];

      await openChat(tester);

      expect(find.byType(ChatCallEntryTile), findsNWidgets(3));
      expect(find.text('Outgoing call · 2:34'), findsOneWidget);
      expect(find.text('Missed call'), findsOneWidget);
      expect(find.text('Call declined'), findsOneWidget);
    });

    testWidgets('lists a call below the older messages', (
      tester,
    ) async {
      repository.history = [
        encrypted('m1', 'before', from: me),
        encrypted('m2', 'after', from: peer),
      ];
      repository.callHistory = [
        call('c1', talked: const Duration(seconds: 5), endReason: 'ended'),
      ];

      await openChat(tester);

      // Both messages are at 2026-01-01, long before the call.
      final call1 = tester.getTopLeft(find.byType(ChatCallEntryTile)).dy;
      expect(tester.getTopLeft(find.text('before')).dy, lessThan(call1));
      expect(tester.getTopLeft(find.text('after')).dy, lessThan(call1));
    });

    testWidgets('adds a call as soon as it ends', (tester) async {
      await openChat(tester);
      expect(find.byType(ChatCallEntryTile), findsNothing);
      final loads = repository.callHistoryRequests;

      repository.callHistory = [call('c1', endReason: 'cancelled')];
      socket.callEvents.add((event: 'call:ended', data: {'callId': 'c1'}));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(repository.callHistoryRequests, loads + 1);
      expect(find.text('Cancelled call'), findsOneWidget);
    });

    testWidgets('other call events do not reload it', (tester) async {
      await openChat(tester);
      final loads = repository.callHistoryRequests;

      socket.callEvents.add((event: 'call:incoming', data: {'callId': 'c1'}));
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }

      expect(repository.callHistoryRequests, loads);
    });

    testWidgets('loads again when the connection comes back', (tester) async {
      await openChat(tester);
      final loads = repository.callHistoryRequests;

      socket.connections.add(null);
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }

      expect(repository.callHistoryRequests, loads + 1);
    });
  });
}
