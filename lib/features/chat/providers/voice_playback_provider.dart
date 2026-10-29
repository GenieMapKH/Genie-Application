import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/features/chat/data/chat_attachment_service.dart';
import 'package:tilomnov/features/chat/data/voice/voice_player.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';

/// Which voice message is loaded and how far it has played.
class VoicePlaybackState {
  static const speeds = [1.0, 1.5, 2.0];

  /// The message loaded in the player, if any.
  final String? messageId;
  final bool loading;
  final bool playing;
  final Duration position;
  final double speed;

  /// A message that could not be opened. Its bubble offers to try again.
  final String? failedMessageId;

  const VoicePlaybackState({
    this.messageId,
    this.loading = false,
    this.playing = false,
    this.position = Duration.zero,
    this.speed = 1.0,
    this.failedMessageId,
  });

  VoicePlaybackState copyWith({
    bool? loading,
    bool? playing,
    Duration? position,
    double? speed,
  }) {
    return VoicePlaybackState(
      messageId: messageId,
      loading: loading ?? this.loading,
      playing: playing ?? this.playing,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      failedMessageId: failedMessageId,
    );
  }
}

/// Plays the voice messages of the open conversation, one at a time.
/// Starting another stops the first, as in every messaging app.
class VoicePlaybackNotifier extends StateNotifier<VoicePlaybackState> {
  final VoicePlayer player;
  final ChatAttachmentService attachments;

  final _subscriptions = <StreamSubscription<void>>[];

  VoicePlaybackNotifier({required this.player, required this.attachments})
    : super(const VoicePlaybackState()) {
    _subscriptions
      ..add(player.positions.listen(_onPosition))
      ..add(player.completions.listen((_) => _onCompleted()));
  }

  /// Plays [message], or pauses it when it is the one playing.
  Future<void> toggle(ChatMessage message) async {
    if (message.id == state.messageId && !state.loading) {
      if (state.playing) {
        state = state.copyWith(playing: false);
        await player.pause();
      } else {
        state = state.copyWith(playing: true);
        await player.play();
      }
      return;
    }
    await _start(message);
  }

  /// Moves the playing message to [fraction] of its length.
  Future<void> seek(ChatMessage message, double fraction) async {
    final voice = message.voice;
    if (message.id != state.messageId || state.loading || voice == null) {
      return;
    }
    final position = voice.duration * fraction.clamp(0.0, 1.0);
    state = state.copyWith(position: position);
    await player.seek(position);
  }

  /// 1×, 1.5×, 2×, then back to 1×. Kept for the next message too.
  Future<void> cycleSpeed() async {
    final speeds = VoicePlaybackState.speeds;
    final next = speeds[(speeds.indexOf(state.speed) + 1) % speeds.length];
    state = state.copyWith(speed: next);
    await player.setSpeed(next);
  }

  /// Stops playing, e.g. when a call starts.
  Future<void> stop() async {
    if (state.messageId == null) return;
    state = VoicePlaybackState(speed: state.speed);
    await player.pause();
  }

  Future<void> _start(ChatMessage message) async {
    final speed = state.speed;
    final wasPlaying = state.playing;
    state = VoicePlaybackState(
      messageId: message.id,
      loading: true,
      speed: speed,
    );
    // The previous message stops at once, not once this one has downloaded.
    if (wasPlaying) await player.pause();

    try {
      final file = await _fileOf(message);
      if (!mounted || state.messageId != message.id) return;
      await player.load(file.bytes, file.mimeType);
      await player.setSpeed(speed);
      if (!mounted || state.messageId != message.id) return;
      state = state.copyWith(loading: false, playing: true);
      await player.play();
    } catch (e, stackTrace) {
      AppLogger.error('Voice message could not be played', e, stackTrace);
      if (!mounted || state.messageId != message.id) return;
      state = VoicePlaybackState(speed: speed, failedMessageId: message.id);
    }
  }

  /// The recording itself while it is still being sent; else the stored
  /// file, opened in memory.
  Future<({Uint8List bytes, String mimeType})> _fileOf(
    ChatMessage message,
  ) async {
    final local = message.localVoice;
    if (local != null) return (bytes: local.bytes, mimeType: local.mimeType);

    final attachment = message.attachment;
    if (attachment == null || !attachment.isVoice) {
      throw StateError('Not a voice message');
    }
    return (
      bytes: await attachments.open(attachment),
      mimeType: attachment.mimeType,
    );
  }

  void _onPosition(Duration position) {
    if (state.messageId == null || state.loading || !state.playing) return;
    state = state.copyWith(position: position);
  }

  void _onCompleted() {
    if (state.messageId == null) return;
    state = VoicePlaybackState(speed: state.speed);
    unawaited(player.pause());
    unawaited(player.seek(Duration.zero));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    unawaited(player.dispose());
    super.dispose();
  }
}

/// Makes the player; replaced in tests.
final voicePlayerFactoryProvider = Provider<VoicePlayer Function()>(
  (ref) => JustAudioVoicePlayer.new,
);

/// Lives as long as a conversation screen watches it: leaving the screen
/// stops playback.
final voicePlaybackProvider =
    StateNotifierProvider.autoDispose<
      VoicePlaybackNotifier,
      VoicePlaybackState
    >(
      (ref) => VoicePlaybackNotifier(
        player: ref.watch(voicePlayerFactoryProvider)(),
        attachments: ref.watch(chatAttachmentServiceProvider),
      ),
    );
