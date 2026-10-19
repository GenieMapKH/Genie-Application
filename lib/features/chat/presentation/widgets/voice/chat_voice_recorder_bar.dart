import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_duration_text.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_waveform.dart';
import 'package:genie/features/chat/providers/voice_recording_provider.dart';
import 'package:genie/l10n/l10n.dart';

/// Takes the place of the message field while a voice message is recorded:
/// how long it is so far and how loud, with a way to throw it away or send.
class ChatVoiceRecorderBar extends StatelessWidget {
  final VoiceRecordingState recording;
  final VoidCallback onDiscard;
  final VoidCallback onSend;

  const ChatVoiceRecorderBar({
    super.key,
    required this.recording,
    required this.onDiscard,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final recordingNow = recording.status == VoiceRecordingStatus.recording;
    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.only(
        left: 8,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.chatDiscardVoice,
            icon: Icon(Icons.delete_outline, color: context.colors.danger),
            onPressed: recordingNow ? onDiscard : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.iconSubtle),
              ),
              child: Row(
                children: [
                  _RecordingDot(color: context.colors.danger),
                  const SizedBox(width: 8),
                  Semantics(
                    liveRegion: true,
                    label: context.l10n.chatRecordingVoice,
                    child: Text(
                      voiceDurationText(recording.elapsed),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VoiceWaveform(
                      levels: recording.recentLevels,
                      color: context.colors.accent,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton.filled(
              tooltip: context.l10n.chatSendVoice,
              style: IconButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: context.colors.onPrimary,
              ),
              icon: recordingNow
                  ? const Icon(Icons.send_rounded, size: 20)
                  : SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.onPrimary,
                      ),
                    ),
              onPressed: recordingNow ? onSend : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades in and out while recording, as a microphone light would.
class _RecordingDot extends StatefulWidget {
  final Color color;

  const _RecordingDot({required this.color});

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_pulse),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
