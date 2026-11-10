import 'package:tilomnov/features/call/presentation/mini_call_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/device/microphone_permission.dart';
import 'package:tilomnov/features/call/application/call_controller.dart';
import 'package:tilomnov/features/call/data/call_signaling.dart';
import 'package:tilomnov/features/call/presentation/call_screen.dart';
import 'package:tilomnov/features/call/providers/call_providers.dart';
import 'package:tilomnov/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:tilomnov/features/chat/providers/chat_call_starter.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';

import '../chat/chat_fakes.dart';
import 'call_fakes.dart';
import '../safety/fake_block_repository.dart';

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

  Future<void> showScreen(
    WidgetTester tester, {
    bool allowUnlock = true,
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('tilomnov/call'),
      (call) async => allowUnlock,
    );
    makeController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [callControllerProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: CallScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'minimize keeps the call connected and the mini bar restores it',
    (tester) async {
      await showScreen(tester);
      await controller.call('bob', 'Bob');
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CallScreen)),
      );
      await tester.tap(find.byTooltip('Minimize call'));
      await tester.pump();
      expect(container.read(callMinimizedProvider), isTrue);
      expect(controller.state.isLive, isTrue);
      expect(signaling.sent, ['invite bob']);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [callControllerProvider.overrideWith((ref) => controller)],
          child: MaterialApp(
            home: const Scaffold(body: Text('Conversations')),
            builder: (context, child) =>
                Stack(children: [child!, const MiniCallBar()]),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Bob'), findsOneWidget);
      await tester.tap(find.text('Bob'));
      await tester.pump();
      expect(container.read(callMinimizedProvider), isFalse);
      expect(controller.state.isLive, isTrue);
      await controller.hangUp();
      await tester.pump(CallController.endedShownFor);
    },
  );

  testWidgets('a ringing call can be answered or declined', (tester) async {
    await showScreen(tester, allowUnlock: false);
    signaling.eventStream.add(
      const CallIncoming('c9', callerId: 'alice', callerName: 'Alice'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Incoming voice call'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    // The incoming screen may be above the keyguard; Back must not expose listings.
    expect(find.byTooltip('Minimize call'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CallScreen)),
    );
    expect(container.read(callMinimizedProvider), isFalse);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.pump();

    expect(signaling.sent, ['accept']);
    expect(find.text('Connecting…'), findsOneWidget);
  });

  testWidgets('cancelling device unlock keeps the call screen in place', (
    tester,
  ) async {
    await showScreen(tester, allowUnlock: false);
    await controller.call('bob', 'Bob');
    await tester.pump();
    await tester.tap(find.byTooltip('Minimize call'));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CallScreen)),
    );
    expect(container.read(callMinimizedProvider), isFalse);
    await controller.hangUp();
    await tester.pump(CallController.endedShownFor);
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

  testWidgets('"Call ended" stays centred once the buttons are gone', (
    tester,
  ) async {
    await showScreen(tester);
    await controller.call('bob', 'Bob');
    await tester.pump();
    await controller.hangUp();
    await tester.pump();

    final screen = tester.getRect(find.byType(Scaffold));
    final status = tester.getRect(find.text('Call ended'));
    expect(status.center.dx, closeTo(screen.center.dx, 1));
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
          noBlocksOverride(),
          messageCodecProvider.overrideWith((ref, userId) => FakeCipher()),
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
