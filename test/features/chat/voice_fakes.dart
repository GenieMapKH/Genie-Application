import 'dart:async';
import 'dart:typed_data';

import 'package:tilomnov/features/chat/data/voice/voice_player.dart';
import 'package:tilomnov/features/chat/data/voice/voice_recorder.dart';
import 'package:tilomnov/features/chat/models/chat_attachment.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_voice.dart';

import 'chat_fakes.dart';

class FakeVoiceRecorder implements VoiceRecorder {
  final levelStream = StreamController<double>.broadcast();
  Object? startError;
  RecordedAudio? result = (
    bytes: Uint8List.fromList([7, 7, 7]),
    mimeType: 'audio/mp4',
    extension: 'm4a',
  );
  bool started = false;
  bool cancelled = false;
  bool disposed = false;

  @override
  Future<void> start() async {
    if (startError != null) throw startError!;
    started = true;
  }

  @override
  Stream<double> levels() => levelStream.stream;

  @override
  Future<RecordedAudio?> stop() async => result;

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeVoicePlayer implements VoicePlayer {
  final positionStream = StreamController<Duration>.broadcast();
  final completionStream = StreamController<void>.broadcast();
  final loaded = <Uint8List>[];
  bool playing = false;
  double speed = 1;
  Duration? seekedTo;

  @override
  Future<Duration?> load(Uint8List bytes, String mimeType) async {
    loaded.add(bytes);
    return const Duration(seconds: 3);
  }

  @override
  Future<void> play() async => playing = true;

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> seek(Duration position) async => seekedTo = position;

  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;

  @override
  Stream<Duration> get positions => positionStream.stream;

  @override
  Stream<void> get completions => completionStream.stream;

  @override
  Future<void> dispose() async {}
}

/// A clock the tests move by hand.
class TestClock {
  DateTime now = DateTime.utc(2026, 1, 1, 12);
  DateTime call() => now;
}

const threeSecondVoice = ChatVoiceDetails(
  duration: Duration(seconds: 3),
  waveform: [0, 10, 31, 5],
);

ChatAttachment voiceAttachment(int n) => fakeAttachment(
  n,
  name: 'voice-message.m4a',
  mimeType: 'audio/mp4',
  voice: threeSecondVoice,
);

ChatMessage voiceMessage(String id, ChatAttachment attachment) => ChatMessage(
  id: id,
  senderId: peer,
  recipientId: me,
  text: '',
  createdAt: DateTime.utc(2026),
  attachment: attachment,
);
