import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/data/voice/voice_recorder.dart';
import 'package:genie/features/chat/presentation/widgets/voice/live_voice_waveform.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_duration_text.dart';
import 'package:genie/features/chat/providers/voice_recording_provider.dart';
import 'package:genie/l10n/l10n.dart';

/// A recording under way, in a rounded field: a pulsing dot, how long it is
/// so far, and how loud. [trailing] (a hint) sits at the end when given.
class VoiceRecordingProgress extends StatelessWidget {
  final VoiceRecordingState recording;
  final Widget? trailing;

  const VoiceRecordingProgress({
    super.key,
    required this.recording,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: LiveVoiceWaveform(
              levels: recording.recentLevels,
              // One fewer than kept: the oldest bar is sliding out of view.
              capacity: VoiceRecordingState.shownLevels - 1,
              sampleInterval: levelInterval,
              moving: recording.status == VoiceRecordingStatus.recording,
              color: context.colors.accent,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
