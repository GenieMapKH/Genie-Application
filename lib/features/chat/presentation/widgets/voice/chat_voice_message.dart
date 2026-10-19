import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_voice.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_duration_text.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_waveform.dart';
import 'package:genie/features/chat/providers/voice_playback_provider.dart';
import 'package:genie/l10n/l10n.dart';

/// A voice message in a conversation: play or pause, its waveform (tap or
/// drag it to jump), how long it is, and the playback speed while it plays.
class ChatVoiceMessage extends ConsumerWidget {
  static const _width = 240.0;

  final ChatMessage message;
  final ChatVoiceDetails voice;
  final bool isMine;

  /// Replaces playing, e.g. to retry a failed send.
  final VoidCallback? onTap;

  const ChatVoiceMessage({
    super.key,
    required this.message,
    required this.voice,
    required this.isMine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(voicePlaybackProvider);
    final player = ref.read(voicePlaybackProvider.notifier);
    final isCurrent = playback.messageId == message.id;
    final failed = playback.failedMessageId == message.id;
    final foreground = isMine
        ? context.colors.onPrimary
        : context.colors.textPrimary;
    final faded = foreground.withValues(alpha: 0.35);

    final position = isCurrent ? playback.position : Duration.zero;
    final progress = voice.duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / voice.duration.inMilliseconds;

    return Semantics(
      label:
          '${context.l10n.chatVoiceMessage}, '
          '${voiceDurationText(voice.duration)}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _width,
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          decoration: BoxDecoration(
            color: isMine ? context.colors.accent : context.colors.surface,
            border: isMine ? null : Border.all(color: context.colors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _PlayButton(
                    loading: isCurrent && playback.loading,
                    playing: isCurrent && playback.playing,
                    color: foreground,
                    onPressed: onTap ?? () => player.toggle(message),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VoiceWaveform(
                      levels: [
                        for (final level in voice.waveform)
                          level / ChatVoiceDetails.maxLevel,
                      ],
                      progress: progress,
                      color: faded,
                      playedColor: foreground,
                      onSeek: isCurrent && onTap == null
                          ? (fraction) => player.seek(message, fraction)
                          : null,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Row(
                  children: [
                    Text(
                      voiceDurationText(
                        isCurrent && position > Duration.zero
                            ? position
                            : voice.duration,
                      ),
                      style: GoogleFonts.inter(fontSize: 11, color: foreground),
                    ),
                    const Spacer(),
                    if (isCurrent && !playback.loading)
                      _SpeedChip(
                        speed: playback.speed,
                        color: foreground,
                        onPressed: player.cycleSpeed,
                      ),
                  ],
                ),
              ),
              if (failed)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 44),
                  child: Text(
                    context.l10n.chatVoiceUnavailable,
                    style: GoogleFonts.inter(fontSize: 11, color: foreground),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool loading;
  final bool playing;
  final Color color;
  final VoidCallback onPressed;

  const _PlayButton({
    required this.loading,
    required this.playing,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: loading
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              tooltip: playing
                  ? context.l10n.chatPauseVoice
                  : context.l10n.chatPlayVoice,
              icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: color,
                size: 30,
              ),
              onPressed: onPressed,
            ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final double speed;
  final Color color;
  final VoidCallback onPressed;

  const _SpeedChip({
    required this.speed,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = speed == speed.roundToDouble()
        ? '${speed.toInt()}×'
        : '$speed×';
    return Semantics(
      button: true,
      label: '${context.l10n.chatVoiceSpeed} $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
