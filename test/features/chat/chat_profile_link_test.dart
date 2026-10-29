import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/models/chat_participant.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_conversation_header.dart';
import 'package:tilomnov/features/chat/providers/chat_participant_providers.dart';
import 'package:tilomnov/features/chat/providers/chat_profile_opener.dart';

import '../../support/test_app.dart';

const _chat = (userId: 'me', participantId: 'u-1');

List<Override> _participant() => [
  chatParticipantProfileProvider.overrideWith(
    (ref, id) async => ChatParticipantProfile(
      id: id,
      name: 'Sokha Realty',
      username: 'sokha_realty',
      avatarUrl: null,
      memberSince: DateTime(2025, 3),
    ),
  ),
  chatPresenceProvider.overrideWith((ref, id) => const Stream.empty()),
];

Future<void> _pumpHeader(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await pumpTestApp(
    tester,
    Scaffold(
      appBar: AppBar(
        title: const ChatConversationHeader(
          participantName: 'Sokha Realty',
          chat: _chat,
        ),
      ),
    ),
    overrides: [..._participant(), ...overrides],
  );
  await tester.pumpAndSettle();
}

Override _safetyCode() =>
    chatSafetyCodeProvider.overrideWith((ref, chat) async => '12345 67890');

void main() {
  testWidgets(
    'tapping who you chat with opens Profile and Security code tabs',
    (tester) async {
      await _pumpHeader(tester, overrides: [_safetyCode()]);

      await tester.tap(find.text('Sokha Realty'));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Security code'), findsOneWidget);
      // Profile first: the handle and when they joined.
      expect(find.text('@sokha_realty'), findsOneWidget);
      expect(find.text('Member since March 2025'), findsOneWidget);
      expect(find.text('12345 67890'), findsNothing);

      await tester.tap(find.text('Security code'));
      await tester.pumpAndSettle();

      expect(find.text('12345 67890'), findsOneWidget);
      expect(find.text('@sokha_realty'), findsNothing);
    },
  );

  testWidgets('"View full profile" closes the sheet and opens their profile', (
    tester,
  ) async {
    final opened = <ChatProfileTarget>[];
    await _pumpHeader(
      tester,
      overrides: [
        _safetyCode(),
        chatProfileOpenerProvider.overrideWithValue(
          (context, target) async => opened.add(target),
        ),
      ],
    );
    await tester.tap(find.text('Sokha Realty'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View full profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsNothing, reason: 'the sheet closed');
    expect(opened.single.userId, 'u-1');
    expect(opened.single.name, 'Sokha Realty');
    expect(opened.single.username, 'sokha_realty');
  });

  testWidgets('without a profile page wired, there is no button for it', (
    tester,
  ) async {
    await _pumpHeader(tester, overrides: [_safetyCode()]);

    await tester.tap(find.text('Sokha Realty'));
    await tester.pumpAndSettle();

    expect(find.text('View full profile'), findsNothing);
  });
}
