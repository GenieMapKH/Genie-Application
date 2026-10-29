import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/device/microphone_permission.dart';
import 'package:tilomnov/features/call/application/call_controller.dart';
import 'package:tilomnov/features/call/data/call_media.dart';
import 'package:tilomnov/features/call/data/call_signaling.dart';
import 'package:tilomnov/features/call/models/call_state.dart';
import 'package:tilomnov/features/chat/data/chat_socket_service.dart';

import 'call_fakes.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('reading call events', () {
    CallEvent? read(String event, Map<String, dynamic> data) =>
        CallEvent.fromSocket((event: event, data: data));

    test('an incoming call names who is calling', () {
      final event = read('call:incoming', {
        'callId': 'c1',
        'callerId': 'alice',
        'callerName': 'Alice',
      });

      expect(event, isA<CallIncoming>());
      expect((event as CallIncoming).callerName, 'Alice');
    });

    test('signals carry an offer, an answer or a candidate', () {
      final offer = read('call:signal', {
        'callId': 'c1',
        'type': 'offer',
        'sdp': 'v=0',
      });
      final candidate = read('call:signal', {
        'callId': 'c1',
        'type': 'candidate',
        'candidate': 'candidate:1',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
      });

      expect((offer as CallSignal).description, (type: 'offer', sdp: 'v=0'));
      expect((candidate as CallSignal).candidate?.sdpMLineIndex, 0);
    });

    test('anything incomplete is ignored', () {
      expect(read('call:incoming', {'callId': 'c1'}), isNull);
      expect(read('call:signal', {'callId': 'c1', 'type': 'offer'}), isNull);
      expect(read('call:ended', {}), isNull);
      expect(read('call:unknown', {'callId': 'c1'}), isNull);
    });
  });

  group('CallController', () {
    late FakeCallSignaling signaling;
    late List<FakeCallMedia> media;
    late MicrophoneAccess microphone;
    late List<String> log;
    late DateTime now;
    late CallController controller;

    setUp(() {
      log = [];
      signaling = FakeCallSignaling();
      media = [];
      microphone = MicrophoneAccess.granted;
      now = DateTime.utc(2026, 10, 19, 12);
      controller = CallController(
        signaling: signaling,
        newMedia: () {
          final next = FakeCallMedia(log: log);
          media.add(next);
          return next;
        },
        requestMicrophone: () async => microphone,
        newCallId: () => 'c1',
        now: () => now,
      );
    });

    tearDown(() {
      if (controller.mounted) controller.dispose();
    });

    void server(CallEvent event) => signaling.eventStream.add(event);

    group('calling someone', () {
      test('rings them, then connects once they answer', () async {
        await controller.call('bob', 'Bob');
        expect(controller.state.phase, CallPhase.outgoing);
        expect(signaling.sent, ['invite bob']);

        server(const CallAccepted('c1'));
        await _settle();
        expect(controller.state.phase, CallPhase.connecting);
        expect(media.single.steps, ['open', 'offer']);
        expect(signaling.descriptions.single.type, 'offer');

        server(
          const CallSignal(
            'c1',
            description: (type: 'answer', sdp: 'v=0 answer'),
          ),
        );
        await _settle();
        media.single.connectionStream.add(MediaConnection.connected);
        await _settle();

        expect(media.single.steps.last, 'accept-answer v=0 answer');
        expect(controller.state.phase, CallPhase.active);
        expect(controller.state.connectedAt, now);
      });

      test('says so when they are on another call', () async {
        signaling.inviteRefusal = 'busy';

        await controller.call('bob', 'Bob');

        expect(controller.state.phase, CallPhase.ended);
        expect(controller.state.endReason, CallEndReason.busy);
      });

      test('without the microphone nobody is rung', () async {
        microphone = MicrophoneAccess.blockedInSettings;

        await controller.call('bob', 'Bob');

        expect(signaling.sent, isEmpty);
        expect(controller.state.endReason, CallEndReason.microphoneDenied);
      });

      test('hearing nobody answer', () async {
        await controller.call('bob', 'Bob');

        server(const CallEnded('c1', reason: 'missed'));
        await _settle();

        expect(controller.state.endReason, CallEndReason.noAnswer);
      });

      test('hanging up ends it and turns the microphone off', () async {
        await controller.call('bob', 'Bob');
        server(const CallAccepted('c1'));
        await _settle();

        await controller.hangUp();

        expect(signaling.sent.last, 'hangup');
        expect(media.single.closed, isTrue);
        expect(controller.state.endReason, CallEndReason.hungUp);
      });

      test('one call at a time', () async {
        await controller.call('bob', 'Bob');
        await controller.call('carol', 'Carol');

        expect(signaling.sent, ['invite bob']);
      });
    });

    group('being called', () {
      void ring() => server(
        const CallIncoming('c9', callerId: 'alice', callerName: 'Alice'),
      );

      test('rings with the caller\'s name', () async {
        ring();
        await _settle();

        expect(controller.state.phase, CallPhase.incoming);
        expect(controller.state.peerName, 'Alice');
        expect(controller.state.isCaller, isFalse);
      });

      test(
        'answering readies the audio first, then answers their offer',
        () async {
          ring();
          await _settle();

          await controller.accept();
          signaling.sent.forEach(log.add);
          expect(log, ['open', 'accept']);

          server(
            const CallSignal(
              'c9',
              description: (type: 'offer', sdp: 'v=0 offer'),
            ),
          );
          server(
            const CallSignal(
              'c9',
              candidate: (
                candidate: 'candidate:7',
                sdpMid: '0',
                sdpMLineIndex: 0,
              ),
            ),
          );
          await _settle();

          expect(media.single.steps, [
            'open',
            'answer v=0 offer',
            'candidate candidate:7',
          ]);
          expect(signaling.descriptions.single.type, 'answer');
        },
      );

      test('declining tells the server', () async {
        ring();
        await _settle();

        await controller.decline();

        expect(signaling.sent, ['decline']);
        expect(controller.state.endReason, CallEndReason.declined);
      });

      test('answered on another device stops ringing here', () async {
        ring();
        await _settle();

        server(const CallAnsweredElsewhere('c9'));
        await _settle();

        expect(controller.state.endReason, CallEndReason.answeredElsewhere);
      });

      test('a second call while in one is ignored', () async {
        await controller.call('bob', 'Bob');

        ring();
        await _settle();

        expect(controller.state.callId, 'c1');
        expect(controller.state.phase, CallPhase.outgoing);
      });

      test('a call too late to answer, from an old push, does not ring', () {
        controller.ringFromPush(
          callId: 'c9',
          callerId: 'alice',
          callerName: 'Alice',
          sentAt: now.subtract(const Duration(minutes: 2)),
        );

        expect(controller.state.isIdle, isTrue);
      });

      test('a fresh push rings like the connection would', () {
        controller.ringFromPush(
          callId: 'c9',
          callerId: 'alice',
          callerName: 'Alice',
          sentAt: now.subtract(const Duration(seconds: 5)),
        );

        expect(controller.state.phase, CallPhase.incoming);
      });
    });

    test('a lost connection to the server ends the call', () async {
      await controller.call('bob', 'Bob');

      signaling.reconnectStream.add(null);
      await _settle();

      expect(controller.state.endReason, CallEndReason.connectionLost);
    });

    test('audio that drops ends the call', () async {
      await controller.call('bob', 'Bob');
      server(const CallAccepted('c1'));
      await _settle();

      media.single.connectionStream.add(MediaConnection.lost);
      await _settle();

      expect(signaling.sent.last, 'hangup');
      expect(controller.state.phase, CallPhase.ended);
    });

    test('mute and speaker reach the audio', () async {
      await controller.call('bob', 'Bob');
      server(const CallAccepted('c1'));
      await _settle();

      await controller.toggleMute();
      await controller.toggleSpeaker();

      expect(media.single.muted, isTrue);
      expect(media.single.speaker, isTrue);
      expect(controller.state.muted, isTrue);
    });

    testWidgets('the ended screen goes away by itself', (tester) async {
      await controller.call('bob', 'Bob');
      await controller.hangUp();
      expect(controller.state.phase, CallPhase.ended);

      await tester.pump(CallController.endedShownFor);

      expect(controller.state.isIdle, isTrue);
    });
  });

  test('the chat connection names every call event it passes on', () {
    expect(
      ChatSocketService.callEventNames,
      containsAll(['call:incoming', 'call:signal', 'call:ended']),
    );
  });
}
