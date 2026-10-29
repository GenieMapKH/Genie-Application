import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/device/microphone_permission.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/data/voice/voice_recorder.dart';
import 'package:tilomnov/features/chat/models/chat_voice.dart';
import 'package:tilomnov/features/chat/providers/active_chat_provider.dart';

enum VoiceRecordingStatus { idle, starting, recording, finishing }

/// Why a recording did not start or was not sent. The screen says it.
enum VoiceRecordingProblem {
  microphoneDenied,
  microphoneBlocked,
  tooShort,
  failed,
}

class VoiceRecordingState {
  /// How many recent loudness samples the recording bar draws.
  static const shownLevels = 32;

  final VoiceRecordingStatus status;
  final Duration elapsed;

  /// The latest [shownLevels] loudness samples, oldest first, 0 to 1.
  final List<double> recentLevels;

  final VoiceRecordingProblem? problem;

  const VoiceRecordingState({
    this.status = VoiceRecordingStatus.idle,
    this.elapsed = Duration.zero,
    this.recentLevels = const [],
    this.problem,
  });

  bool get isActive => status != VoiceRecordingStatus.idle;
}

/// Records a voice message for one conversation and hands it to [onRecorded]
/// to be sent. Tap the microphone to start, then send or throw it away.
class VoiceRecordingNotifier extends StateNotifier<VoiceRecordingState> {
  /// Anything shorter is most likely a tap by mistake.
  static const minDuration = Duration(milliseconds: 700);

  static const _tick = Duration(milliseconds: 100);

  final VoiceRecorder recorder;
  final Future<MicrophoneAccess> Function() requestMicrophone;
  final void Function(RecordedVoiceNote note) onRecorded;
  final DateTime Function() _now;

  final _samples = <double>[];
  StreamSubscription<double>? _levels;
  Timer? _ticker;
  DateTime? _startedAt;

  VoiceRecordingNotifier({
    required this.recorder,
    required this.requestMicrophone,
    required this.onRecorded,
    DateTime Function() now = DateTime.now,
  }) : _now = now,
       super(const VoiceRecordingState());

  Future<void> start() async {
    if (state.isActive) return;
    state = const VoiceRecordingState(status: VoiceRecordingStatus.starting);

    final access = await requestMicrophone();
    if (!mounted) return;
    if (access != MicrophoneAccess.granted) {
      state = VoiceRecordingState(
        problem: access == MicrophoneAccess.blockedInSettings
            ? VoiceRecordingProblem.microphoneBlocked
            : VoiceRecordingProblem.microphoneDenied,
      );
      return;
    }

    try {
      await recorder.start();
    } catch (e, stackTrace) {
      AppLogger.error('Voice recording did not start', e, stackTrace);
      if (mounted) {
        state = const VoiceRecordingState(
          problem: VoiceRecordingProblem.failed,
        );
      }
      return;
    }
    if (!mounted) {
      await recorder.cancel();
      return;
    }

    _samples.clear();
    _startedAt = _now();
    _levels = recorder.levels().listen(_onLevel);
    _ticker = Timer.periodic(_tick, (_) => _onTick());
    state = const VoiceRecordingState(status: VoiceRecordingStatus.recording);
  }

  /// Stops and sends what was recorded.
  Future<void> finish() async {
    if (state.status != VoiceRecordingStatus.recording) return;
    final duration = _elapsed();
    _stopWatching();
    state = VoiceRecordingState(
      status: VoiceRecordingStatus.finishing,
      elapsed: duration,
      recentLevels: state.recentLevels,
    );

    final RecordedAudio? audio;
    try {
      audio = await recorder.stop();
    } catch (e, stackTrace) {
      AppLogger.error('Voice recording did not stop cleanly', e, stackTrace);
      if (mounted) {
        state = const VoiceRecordingState(
          problem: VoiceRecordingProblem.failed,
        );
      }
      return;
    }
    if (!mounted) return;

    if (duration < minDuration || audio == null) {
      state = VoiceRecordingState(
        problem: audio == null
            ? VoiceRecordingProblem.failed
            : VoiceRecordingProblem.tooShort,
      );
      return;
    }

    state = const VoiceRecordingState();
    onRecorded(
      RecordedVoiceNote(
        bytes: audio.bytes,
        mimeType: audio.mimeType,
        fileName: 'voice-message.${audio.extension}',
        details: ChatVoiceDetails(
          duration: duration > ChatVoiceDetails.maxDuration
              ? ChatVoiceDetails.maxDuration
              : duration,
          waveform: ChatVoiceDetails.waveformOf(_samples),
        ),
      ),
    );
  }

  /// Stops and throws the recording away.
  Future<void> discard() async {
    if (state.status != VoiceRecordingStatus.recording) return;
    _stopWatching();
    state = const VoiceRecordingState();
    try {
      await recorder.cancel();
    } catch (e, stackTrace) {
      AppLogger.error('Voice recording did not cancel cleanly', e, stackTrace);
    }
  }

  void _onLevel(double level) {
    _samples.add(level);
    final recent = _samples.length > VoiceRecordingState.shownLevels
        ? _samples.sublist(_samples.length - VoiceRecordingState.shownLevels)
        : List<double>.of(_samples);
    state = VoiceRecordingState(
      status: state.status,
      elapsed: state.elapsed,
      recentLevels: recent,
    );
  }

  void _onTick() {
    final elapsed = _elapsed();
    if (elapsed >= ChatVoiceDetails.maxDuration) {
      unawaited(finish());
      return;
    }
    state = VoiceRecordingState(
      status: state.status,
      elapsed: elapsed,
      recentLevels: state.recentLevels,
    );
  }

  Duration _elapsed() {
    final startedAt = _startedAt;
    return startedAt == null ? Duration.zero : _now().difference(startedAt);
  }

  void _stopWatching() {
    _ticker?.cancel();
    _ticker = null;
    _levels?.cancel();
    _levels = null;
    _startedAt = null;
  }

  @override
  void dispose() {
    final wasRecording = state.status == VoiceRecordingStatus.recording;
    _stopWatching();
    // Leaving the conversation throws an unsent recording away.
    unawaited(() async {
      try {
        if (wasRecording) await recorder.cancel();
      } finally {
        await recorder.dispose();
      }
    }());
    super.dispose();
  }
}

/// Makes the recorder; replaced in tests.
final voiceRecorderFactoryProvider = Provider<VoiceRecorder Function()>(
  (ref) => DeviceVoiceRecorder.new,
);

/// What a recording is timed with; replaced in tests.
final voiceRecordingClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// One recorder per open conversation; what it records is sent there.
final voiceRecordingProvider = StateNotifierProvider.autoDispose
    .family<VoiceRecordingNotifier, VoiceRecordingState, ChatParticipants>((
      ref,
      chat,
    ) {
      return VoiceRecordingNotifier(
        recorder: ref.watch(voiceRecorderFactoryProvider)(),
        requestMicrophone: ref.watch(microphoneAccessProvider),
        onRecorded: (note) =>
            ref.read(activeChatProvider(chat).notifier).sendVoice(note),
        now: ref.watch(voiceRecordingClockProvider),
      );
    });
