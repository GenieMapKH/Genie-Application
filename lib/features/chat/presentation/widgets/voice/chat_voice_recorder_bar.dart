import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/presentation/widgets/voice/voice_recording_progress.dart';
import 'package:tilomnov/features/chat/providers/voice_recording_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';

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
          Expanded(child: VoiceRecordingProgress(recording: recording)),
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
