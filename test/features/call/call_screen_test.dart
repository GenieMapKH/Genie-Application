import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/device/microphone_permission.dart';
import 'package:genie/features/call/application/call_controller.dart';
import 'package:genie/features/call/data/call_signaling.dart';
import 'package:genie/features/call/presentation/call_screen.dart';
import 'package:genie/features/call/providers/call_providers.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/providers/chat_call_starter.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

import '../chat/chat_fakes.dart';
import 'call_fakes.dart';

void main() {
  late FakeCallSignaling signaling;
  late CallController controller;

  /// Made inside each test, so its listeners run in the test's clock.
  void makeController() {
    signaling = FakeCallSignaling();
    controller = CallController(
      signaling: signaling,
      newMedia: FakeCallMedia.new,
      requestMicrophone: () async => MicrophoneAccess.granted,
      newCallId: () => 'c1',
    );
  }

  Future<void> showScreen(WidgetTester tester) async {
    makeController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [callControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: CallScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('a ringing call can be answered or declined', (tester) async {
    await showScreen(tester);
    signaling.eventStream.add(
      const CallIncoming('c9', callerId: 'alice', callerName: 'Alice'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Incoming voice call'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump();

    expect(signaling.sent, ['accept']);
    expect(find.text('Connecting…'), findsOneWidget);
  });

  testWidgets('a call being made can be muted and ended', (tester) async {
    await showScreen(tester);
    await controller.call('bob', 'Bob');
    await tester.pump();

    expect(find.text('Calling…'), findsOneWidget);
    await tester.tap(find.text('Mute'));
    await tester.pump();
    expect(find.text('Unmute'), findsOneWidget);

    await tester.tap(find.text('End call'));
    await tester.pump();
    await tester.pump();

    expect(signaling.sent.last, 'hangup');
    expect(find.text('Call ended'), findsOneWidget);
    expect(find.text('End call'), findsNothing);
    await tester.pump(CallController.endedShownFor);
  });

  testWidgets('says why a call could not happen', (tester) async {
    await showScreen(tester);
    signaling.inviteRefusal = 'busy';

    await controller.call('bob', 'Bob');
    await tester.pump();

    expect(find.text('On another call'), findsOneWidget);
    await tester.pump(CallController.endedShownFor);
  });

  testWidgets("a conversation's call button calls the other person", (
    tester,
  ) async {
    final calls = <String>[];
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
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatSocketServiceProvider.overrideWithValue(FakeChatSocket()),
          e2eeSetupServiceProvider.overrideWithValue(FakeSetupService()),
          messageCipherProvider.overrideWith((ref, userId) => FakeCipher()),
          chatAttachmentServiceProvider.overrideWithValue(
            FakeAttachmentService(),
          ),
          chatCallStarterProvider.overrideWithValue(
            (id, name) async => calls.add('$id $name'),
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

    await tester.tap(find.byTooltip('Voice call'));

    expect(calls, ['$peer Dara']);
  });
}
