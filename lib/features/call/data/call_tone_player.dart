import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// The sounds a call makes on this phone, besides the other person's voice.
enum CallTone {
  /// "Toot-toot": the other phone is ringing. Repeats until stopped.
  ringback('ringback.wav', loops: true),

  /// The other person picked up.
  answered('answered.wav'),

  /// Busy beeps: the call was declined, or the person is busy.
  rejected('rejected.wav');

  final String file;
  final bool loops;
  const CallTone(this.file, {this.loops = false});
}

/// Plays one [CallTone] at a time.
abstract interface class CallTonePlayer {
  /// Stops any tone playing and starts [tone].
  Future<void> play(CallTone tone);

  Future<void> stop();

  Future<void> dispose();
}

/// [CallTonePlayer] using just_audio, from the app's assets.
class JustAudioCallTonePlayer implements CallTonePlayer {
  /// Made at the first tone, not before anyone calls.
  AudioPlayer? _player;

  /// Bumped by every request, so a tone still loading when the next request
  /// arrives never starts.
  int _request = 0;

  /// The call's audio session belongs to WebRTC: the tones play inside it
  /// and never take it over.
  AudioPlayer get _audio => _player ??= AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false,
    androidApplyAudioAttributes: false,
  );

  @override
  Future<void> play(CallTone tone) async {
    final request = ++_request;
    final player = _audio;
    await player.stop();
    await player.setAsset('assets/sounds/call/${tone.file}');
    await player.setLoopMode(tone.loops ? LoopMode.one : LoopMode.off);
    if (request != _request) return;
    // just_audio's play() completes only when playback stops.
    unawaited(player.play());
  }

  @override
  Future<void> stop() async {
    _request++;
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    _request++;
    await _player?.dispose();
    _player = null;
  }
}
