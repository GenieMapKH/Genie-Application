import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/device/microphone_permission.dart';
import 'package:genie/features/call/application/call_controller.dart';
import 'package:genie/features/call/application/call_tones.dart';
import 'package:genie/features/call/data/call_media.dart';
import 'package:genie/features/call/data/call_signaling.dart';
import 'package:genie/features/call/data/call_tone_player.dart';

import 'call_fakes.dart';

/// Records the tones asked for, in order.
class FakeCallTonePlayer implements CallTonePlayer {
  final played = <String>[];

  @override
  Future<void> play(CallTone tone) async => played.add(tone.name);

  @override
  Future<void> stop() async => played.add('stop');

  @override
  Future<void> dispose() async {}
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeCallSignaling signaling;
  late List<FakeCallMedia> media;
  late FakeCallTonePlayer player;
  late CallController controller;

  setUp(() {
    signaling = FakeCallSignaling();
    media = [];
    player = FakeCallTonePlayer();
    controller = CallController(
      signaling: signaling,
      newMedia: () {
        final next = FakeCallMedia();
        media.add(next);
        return next;
      },
      requestMicrophone: () async => MicrophoneAccess.granted,
      newCallId: () => 'c1',
    );
    // The same wiring as the app: every change, with the one before it.
    final tones = CallTones(player);
    var previous = controller.state;
    controller.addListener((call) {
      tones.update(previous, call);
      previous = call;
    }, fireImmediately: false);
  });

  tearDown(() async {
    signaling.eventStream.add(const CallEnded('c1', reason: 'ended'));
    await _settle();
    controller.dispose();
  });

  Future<void> answeredAndConnected() async {
    signaling.eventStream.add(const CallAccepted('c1'));
    await _settle();
    media.single.connectionStream.add(MediaConnection.connected);
    await _settle();
  }

  test(
    'the caller hears ringback until the call connects, then a chime',
    () async {
      await controller.call('bob', 'Bob');
      await _settle();
      expect(player.played, ['ringback']);

      await answeredAndConnected();

      expect(player.played, ['ringback', 'stop', 'answered']);
    },
  );

  test('the caller hears busy beeps when the call is declined', () async {
    await controller.call('bob', 'Bob');
    signaling.eventStream.add(const CallEnded('c1', reason: 'declined'));
    await _settle();

    expect(player.played, ['ringback', 'rejected']);
  });

  test('a busy or unreachable person also gives busy beeps', () async {
    signaling.inviteRefusal = 'busy';
    await controller.call('bob', 'Bob');
    await _settle();

    expect(player.played, ['ringback', 'rejected']);
  });

  test('cancelling or no answer only stops the ringback', () async {
    await controller.call('bob', 'Bob');
    await controller.hangUp();
    await _settle();

    expect(player.played, ['ringback', 'stop']);
  });

  test('the callee hears the chime when the call connects', () async {
    signaling.eventStream.add(
      const CallIncoming('c1', callerId: 'alice', callerName: 'Alice'),
    );
    await _settle();
    await controller.accept();
    await _settle();
    expect(player.played, isEmpty);

    signaling.eventStream.add(
      const CallSignal('c1', description: (type: 'offer', sdp: 'v=0')),
    );
    await _settle();
    media.single.connectionStream.add(MediaConnection.connected);
    await _settle();

    expect(player.played, ['answered']);
  });

  test('a callee who declines hears nothing', () async {
    signaling.eventStream.add(
      const CallIncoming('c1', callerId: 'alice', callerName: 'Alice'),
    );
    await _settle();
    await controller.decline();
    await _settle();

    expect(player.played, isEmpty);
  });

  test('a toggle during the call plays nothing again', () async {
    await controller.call('bob', 'Bob');
    await answeredAndConnected();
    player.played.clear();

    await controller.toggleMute();
    await _settle();

    expect(player.played, isEmpty);
  });
}
