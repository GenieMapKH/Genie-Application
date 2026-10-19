import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// Plays one voice message at a time.
abstract interface class VoicePlayer {
  /// Loads [bytes] in place of whatever was loaded, and returns its length
  /// when the file says it.
  Future<Duration?> load(Uint8List bytes, String mimeType);

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);

  Stream<Duration> get positions;

  /// Fires when the loaded message has played to its end.
  Stream<void> get completions;

  Future<void> dispose();
}

/// [VoicePlayer] using just_audio. The opened file is played straight from
/// memory: a decrypted voice message is never written to the device.
class JustAudioVoicePlayer implements VoicePlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<Duration?> load(Uint8List bytes, String mimeType) =>
      _player.setAudioSource(_BytesAudioSource(bytes, mimeType));

  @override
  Future<void> play() async {
    // just_audio's play() completes only when playback stops.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Stream<Duration> get positions => _player.positionStream;

  @override
  Stream<void> get completions => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> dispose() => _player.dispose();
}

/// Serves an in-memory file to the player, in the ranges it asks for.
/// just_audio marks this API experimental; it is the only way to play a
/// file without writing it to disk first.
// ignore_for_file: experimental_member_use
class _BytesAudioSource extends StreamAudioSource {
  final Uint8List bytes;
  final String mimeType;

  _BytesAudioSource(this.bytes, this.mimeType);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end ?? bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream.value(bytes.sublist(from, to)),
      contentType: mimeType,
    );
  }
}
