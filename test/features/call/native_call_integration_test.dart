import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/call/data/call_notifications.dart';
import 'package:tilomnov/features/call/data/native_call_integration.dart';
import 'package:tilomnov/features/call/models/call_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notificationChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const callChannel = MethodChannel('tilomnov/call');
  final notifications = <MethodCall>[];
  final native = <MethodCall>[];
  NativeCallIntegration? integration;
  const incoming = CallState(
    phase: CallPhase.incoming,
    callId: 'c1',
    peerId: 'alice',
    peerName: 'Alice',
  );

  setUp(() async {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    notifications.clear();
    native.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notificationChannel, (call) async {
      notifications.add(call);
      if (call.method == 'initialize' ||
          call.method == 'requestFullScreenIntentPermission') {
        return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(callChannel, (call) async {
      native.add(call);
      return null;
    });
    await CallNotifications().initialize();
  });

  tearDown(() {
    integration?.dispose();
    integration = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notificationChannel, null);
    messenger.setMockMethodCallHandler(callChannel, null);
  });

  void update(CallState previous, CallState next) {
    integration ??= NativeCallIntegration(
      answer: () async {},
      end: () async {},
      mute: (_) async {},
      restore: () {},
    );
    integration!.update(
      previous,
      next,
      title: 'Call in progress',
      returnLabel: 'Return',
      incomingTitle: 'Alice is calling',
      acceptLabel: 'Accept',
      declineLabel: 'Decline',
      isScreenVisible: () => true,
    );
  }

  testWidgets(
    'a socket call rings and opens above the keyguard only after rendering',
    (tester) async {
      update(const CallState(), incoming);
      await tester.idle();
      final shown =
          notifications.singleWhere((call) => call.method == 'show').arguments
              as Map;
      final details = shown['platformSpecifics'] as Map;
      expect(details['fullScreenIntent'], isTrue);
      expect(details['tag'], 'call:c1');
      expect(jsonDecode(shown['payload'] as String)['callerId'], 'alice');
      expect(native, isEmpty);
      await tester.pump();
      expect((native.single.arguments as Map)['phase'], 'incoming');
      final active = incoming.copyWith(phase: CallPhase.active);
      update(incoming, active);
      await tester.idle();
      expect(notifications.last.method, 'cancel');
      await tester.pump();
      expect((native.last.arguments as Map)['phase'], 'active');
    },
  );

  testWidgets('cancellation does not wait for a paused engine to render', (
    tester,
  ) async {
    update(const CallState(), incoming);
    await tester.idle();
    update(incoming, incoming.copyWith(phase: CallPhase.ended));
    await tester.idle();
    expect(notifications.last.method, 'cancel');
    await tester.pump();
    expect(native.map((call) => (call.arguments as Map)['phase']), ['ended']);
  });

  testWidgets('a speaker change does not discard a pending native update', (
    tester,
  ) async {
    final active = incoming.copyWith(phase: CallPhase.active);
    update(incoming, active);
    update(active, active.copyWith(speakerOn: true));
    await tester.idle();
    await tester.pump();
    expect((native.single.arguments as Map)['phase'], 'active');
  });

  test('an expired push never starts another ringtone', () async {
    await CallNotifications().showIncoming(
      callId: 'old',
      title: 'Alice',
      acceptLabel: 'Accept',
      declineLabel: 'Decline',
      data: {
        'sentAt': DateTime.now()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
      },
    );
    expect(notifications.where((call) => call.method == 'show'), isEmpty);
  });

  test('a delayed push keeps only the remaining ring duration', () async {
    await CallNotifications().showIncoming(
      callId: 'c1',
      title: 'Alice',
      acceptLabel: 'Accept',
      declineLabel: 'Decline',
      data: {
        'sentAt': DateTime.now()
            .subtract(const Duration(seconds: 40))
            .toIso8601String(),
      },
    );
    final shown =
        notifications.singleWhere((call) => call.method == 'show').arguments
            as Map;
    expect(
      (shown['platformSpecifics'] as Map)['timeoutAfter'],
      inInclusiveRange(1, 5000),
    );
  });

  test('full-screen access uses the system permission page', () async {
    await CallNotifications().requestFullScreenPermission();
    expect(notifications.last.method, 'requestFullScreenIntentPermission');
  });
}
