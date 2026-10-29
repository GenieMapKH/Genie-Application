import 'dart:math';
import 'dart:typed_data';

/// What a voice message adds to its audio file: how long it is and the
/// shape of its sound, so the bubble can be drawn before the file is opened.
/// It travels inside the end-to-end encrypted message, like the file's key.
class ChatVoiceDetails {
  /// How many bars a waveform has, and the highest value of a bar.
  static const bars = 40;
  static const maxLevel = 31;

  /// The longest voice message: recording stops on its own here.
  static const maxDuration = Duration(minutes: 5);

  final Duration duration;

  /// [bars] loudness values from 0 (silence) to [maxLevel].
  final List<int> waveform;

  const ChatVoiceDetails({required this.duration, required this.waveform});

  /// Null when [json] is not a complete, plausible description.
  static ChatVoiceDetails? tryParse(Object? json) {
    if (json is! Map) return null;
    final ms = json['ms'];
    final wave = json['wave'];
    if (ms is! int || ms <= 0 || ms > maxDuration.inMilliseconds + 1000) {
      return null;
    }
    if (wave is! List || wave.length > bars * 2) return null;
    return ChatVoiceDetails(
      duration: Duration(milliseconds: ms),
      waveform: [
        for (final level in wave)
          if (level is int) level.clamp(0, maxLevel),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'ms': duration.inMilliseconds,
    'wave': waveform,
  };

  /// Turns loudness samples taken while recording (0 to 1, oldest first)
  /// into [bars] evenly spread bars. Each bar is the loudest sample it
  /// covers, so short syllables still show.
  static List<int> waveformOf(List<double> samples) {
    if (samples.isEmpty) return List.filled(bars, 0);
    return [
      for (var bar = 0; bar < bars; bar++)
        (_loudest(samples, bar) * maxLevel).round().clamp(0, maxLevel),
    ];
  }

  static double _loudest(List<double> samples, int bar) {
    final start = bar * samples.length ~/ bars;
    final end = max(start + 1, (bar + 1) * samples.length ~/ bars);
    var loudest = 0.0;
    for (var i = start; i < end && i < samples.length; i++) {
      loudest = max(loudest, samples[i]);
    }
    return loudest;
  }
}

/// A voice message just recorded on this device, before it is sent.
class RecordedVoiceNote {
  final Uint8List bytes;
  final String mimeType;
  final String fileName;
  final ChatVoiceDetails details;

  const RecordedVoiceNote({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
    required this.details,
  });
}
