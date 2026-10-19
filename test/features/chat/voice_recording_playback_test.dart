import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/device/microphone_permission.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_voice.dart';
import 'package:genie/features/chat/providers/voice_playback_provider.dart';
import 'package:genie/features/chat/providers/voice_recording_provider.dart';

import 'chat_fakes.dart';

import 'voice_fakes.dart';

void main() {
  group('recording', () {
    late FakeVoiceRecorder recorder;
    late TestClock clock;
    late MicrophoneAccess access;
    late List<RecordedVoiceNote> sent;
    late VoiceRecordingNotifier recording;

    setUp(() {
      recorder = FakeVoiceRecorder();
      clock = TestClock();
      access = MicrophoneAccess.granted;
      sent = [];
      recording = VoiceRecordingNotifier(
        recorder: recorder,
        requestMicrophone: () async => access,
        onRecorded: sent.add,
        now: clock.call,
      );
    });

    tearDown(() {
      if (recording.mounted) recording.dispose();
    });

    test('records and hands over the voice message with its shape', () async {
      await recording.start();
      expect(recording.state.status, VoiceRecordingStatus.recording);

      recorder.levelStream
        ..add(0.2)
        ..add(0.9);
      await Future<void>.delayed(Duration.zero);
      expect(recording.state.recentLevels, [0.2, 0.9]);

      clock.now = clock.now.add(const Duration(seconds: 3));
      await recording.finish();

      final note = sent.single;
      expect(note.bytes, [7, 7, 7]);
      expect(note.mimeType, 'audio/mp4');
      expect(note.fileName, 'voice-message.m4a');
      expect(note.details.duration, const Duration(seconds: 3));
      expect(note.details.waveform, hasLength(ChatVoiceDetails.bars));
      expect(recording.state.isActive, isFalse);
    });

    test('a refused microphone is reported and nothing records', () async {
      access = MicrophoneAccess.denied;

      await recording.start();

      expect(recorder.started, isFalse);
      expect(recording.state.problem, VoiceRecordingProblem.microphoneDenied);
      expect(recording.state.isActive, isFalse);
    });

    test('a microphone turned off in settings says where to fix it', () async {
      access = MicrophoneAccess.blockedInSettings;

      await recording.start();

      expect(recording.state.problem, VoiceRecordingProblem.microphoneBlocked);
    });

    test('a recorder that fails to start is reported', () async {
      recorder.startError = Exception('busy');

      await recording.start();

      expect(recording.state.problem, VoiceRecordingProblem.failed);
    });

    test('a tap by mistake is too short to send', () async {
      await recording.start();
      clock.now = clock.now.add(const Duration(milliseconds: 200));

      await recording.finish();

      expect(sent, isEmpty);
      expect(recording.state.problem, VoiceRecordingProblem.tooShort);
    });

    test('a discarded recording is thrown away', () async {
      await recording.start();
      clock.now = clock.now.add(const Duration(seconds: 4));

      await recording.discard();

      expect(recorder.cancelled, isTrue);
      expect(sent, isEmpty);
      expect(recording.state.isActive, isFalse);
    });

    test('leaving the conversation throws an unsent recording away', () async {
      await recording.start();

      recording.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(recorder.cancelled, isTrue);
      expect(recorder.disposed, isTrue);
      expect(sent, isEmpty);
    });

    testWidgets('stops and sends on its own at the time limit', (tester) async {
      await recording.start();

      clock.now = clock.now.add(ChatVoiceDetails.maxDuration);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(sent.single.details.duration, ChatVoiceDetails.maxDuration);
      recording.dispose();
    });
  });

  group('playing', () {
    late FakeVoicePlayer player;
    late FakeAttachmentService attachments;
    late VoicePlaybackNotifier playback;

    setUp(() {
      player = FakeVoicePlayer();
      attachments = FakeAttachmentService();
      playback = VoicePlaybackNotifier(
        player: player,
        attachments: attachments,
      );
    });

    tearDown(() => playback.dispose());

    test('opens the encrypted file and plays it', () async {
      final attachment = voiceAttachment(1);
      attachments.files[attachment.path] = Uint8List.fromList([1, 2]);

      await playback.toggle(voiceMessage('m1', attachment));

      expect(player.loaded.single, [1, 2]);
      expect(player.playing, isTrue);
      expect(playback.state.messageId, 'm1');
      expect(playback.state.playing, isTrue);
    });

    test('tapping again pauses, and again resumes', () async {
      final attachment = voiceAttachment(1);
      attachments.files[attachment.path] = Uint8List.fromList([1]);
      final message = voiceMessage('m1', attachment);
      await playback.toggle(message);

      await playback.toggle(message);
      expect(player.playing, isFalse);
      expect(playback.state.playing, isFalse);

      await playback.toggle(message);
      expect(player.playing, isTrue);
      expect(player.loaded, hasLength(1));
    });

    test('starting another message stops the first', () async {
      final first = voiceAttachment(1);
      final second = voiceAttachment(2);
      attachments.files[first.path] = Uint8List.fromList([1]);
      attachments.files[second.path] = Uint8List.fromList([2]);

      await playback.toggle(voiceMessage('m1', first));
      await playback.toggle(voiceMessage('m2', second));

      expect(playback.state.messageId, 'm2');
      expect(player.loaded.last, [2]);
    });

    test('a message that cannot be opened says so', () async {
      await playback.toggle(voiceMessage('m1', voiceAttachment(1)));

      expect(playback.state.failedMessageId, 'm1');
      expect(playback.state.messageId, isNull);
      expect(player.playing, isFalse);
    });

    test('own message still sending plays from memory', () async {
      final note = RecordedVoiceNote(
        bytes: Uint8List.fromList([5, 5]),
        mimeType: 'audio/mp4',
        fileName: 'voice-message.m4a',
        details: threeSecondVoice,
      );
      final message = ChatMessage(
        id: 'mine',
        senderId: me,
        recipientId: peer,
        text: '',
        createdAt: DateTime.utc(2026),
        localVoice: note,
      );

      await playback.toggle(message);

      expect(player.loaded.single, [5, 5]);
    });

    test('speed goes 1x, 1.5x, 2x and back', () async {
      await playback.cycleSpeed();
      expect(player.speed, 1.5);
      await playback.cycleSpeed();
      expect(player.speed, 2);
      await playback.cycleSpeed();
      expect(player.speed, 1);
    });

    test('jumps to where the waveform was touched', () async {
      final attachment = voiceAttachment(1);
      attachments.files[attachment.path] = Uint8List.fromList([1]);
      final message = voiceMessage('m1', attachment);
      await playback.toggle(message);

      await playback.seek(message, 0.5);

      expect(player.seekedTo, const Duration(milliseconds: 1500));
    });

    test('a finished message goes back to the start', () async {
      final attachment = voiceAttachment(1);
      attachments.files[attachment.path] = Uint8List.fromList([1]);
      await playback.toggle(voiceMessage('m1', attachment));

      player.completionStream.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(playback.state.messageId, isNull);
      expect(player.seekedTo, Duration.zero);
    });
  });
}
