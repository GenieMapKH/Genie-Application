import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/presentation/widgets/voice/voice_recording_progress.dart';
import 'package:tilomnov/features/chat/providers/voice_recording_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// What the message bar shows while the microphone is held down: the
/// recording, and how to throw it away instead of sending it.
class VoiceHoldPanel extends StatelessWidget {
  final VoiceRecordingState recording;

  const VoiceHoldPanel({super.key, required this.recording});

  @override
  Widget build(BuildContext context) {
    final hintColor = context.colors.textMuted;
    return VoiceRecordingProgress(
      recording: recording,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chevron_left, size: 18, color: hintColor),
          Text(
            context.l10n.chatSlideToCancel,
            style: GoogleFonts.inter(fontSize: 13, color: hintColor),
          ),
        ],
      ),
    );
  }
}
