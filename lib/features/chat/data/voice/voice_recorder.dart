import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:genie/core/logging/app_logger.dart';

/// A finished recording, before it becomes a voice message.
typedef RecordedAudio = ({Uint8List bytes, String mimeType, String extension});

/// Records one voice message at a time from the microphone.
abstract interface class VoiceRecorder {
  /// Starts recording. Throws when the microphone cannot be used.
  Future<void> start();

  /// Loudness from 0 (silence) to 1 while recording, every [levelInterval].
  Stream<double> levels();

  /// Stops and returns what was recorded, or null when nothing was.
  Future<RecordedAudio?> stop();

  /// Stops and throws the recording away.
  Future<void> cancel();

  Future<void> dispose();
}

/// How often [VoiceRecorder.levels] reports.
const levelInterval = Duration(milliseconds: 100);

/// A codec, in order of preference: AAC plays everywhere; a browser that
/// cannot record AAC falls back to Opus, then to uncompressed WAV.
typedef _Format = ({AudioEncoder encoder, String mimeType, String extension});

const _formats = <_Format>[
  (encoder: AudioEncoder.aacLc, mimeType: 'audio/mp4', extension: 'm4a'),
  (encoder: AudioEncoder.opus, mimeType: 'audio/webm', extension: 'webm'),
  (encoder: AudioEncoder.wav, mimeType: 'audio/wav', extension: 'wav'),
];

/// [VoiceRecorder] using the device microphone. On a phone the recording is
/// written to a temporary file, read once it stops, then deleted at once.
class DeviceVoiceRecorder implements VoiceRecorder {
  /// Clear speech at about 6 KB per second: five minutes is under 2 MB.
  static const _config = RecordConfig(
    bitRate: 48000,
    sampleRate: 44100,
    numChannels: 1,
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
  );

  /// Quieter than this is drawn as silence.
  static const _silenceDb = -50.0;

  final AudioRecorder _recorder = AudioRecorder();
  _Format? _format;

  @override
  Future<void> start() async {
    final format = await _pickFormat();
    final path = kIsWeb
        ? ''
        : '${(await getTemporaryDirectory()).path}/'
              'voice-${DateTime.now().microsecondsSinceEpoch}.${format.extension}';
    await _recorder.start(
      _config.copyWith(encoder: format.encoder),
      path: path,
    );
    _format = format;
  }

  @override
  Stream<double> levels() => _recorder
      .onAmplitudeChanged(levelInterval)
      .map((amplitude) => _loudness(amplitude.current));

  @override
  Future<RecordedAudio?> stop() async {
    final format = _format;
    _format = null;
    final location = await _recorder.stop();
    if (format == null || location == null || location.isEmpty) return null;

    try {
      // A file path on a phone, a blob URL in a browser.
      final bytes = await XFile(location).readAsBytes();
      return bytes.isEmpty
          ? null
          : (
              bytes: bytes,
              mimeType: format.mimeType,
              extension: format.extension,
            );
    } finally {
      await _deleteFile(location);
    }
  }

  @override
  Future<void> cancel() async {
    _format = null;
    await _recorder.cancel();
  }

  @override
  Future<void> dispose() => _recorder.dispose();

  Future<_Format> _pickFormat() async {
    for (final format in _formats) {
      if (await _recorder.isEncoderSupported(format.encoder)) return format;
    }
    throw StateError('No audio format can be recorded on this device');
  }

  static double _loudness(double db) {
    if (db.isNaN || db <= _silenceDb) return 0;
    return ((db - _silenceDb) / -_silenceDb).clamp(0.0, 1.0);
  }

  /// The plain recording must not stay on the device.
  static Future<void> _deleteFile(String path) async {
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e, stackTrace) {
      AppLogger.error('Recording could not be deleted', e, stackTrace);
    }
  }
}
