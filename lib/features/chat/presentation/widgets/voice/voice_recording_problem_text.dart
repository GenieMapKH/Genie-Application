import 'package:genie/features/chat/providers/voice_recording_provider.dart';
import 'package:genie/l10n/generated/app_localizations.dart';

/// Why a voice message could not be recorded or sent, in the user's language.
String voiceRecordingProblemText(
  AppLocalizations l10n,
  VoiceRecordingProblem problem,
) {
  return switch (problem) {
    VoiceRecordingProblem.microphoneDenied => l10n.microphoneDenied,
    VoiceRecordingProblem.microphoneBlocked => l10n.microphoneBlocked,
    VoiceRecordingProblem.tooShort => l10n.chatVoiceTooShort,
    VoiceRecordingProblem.failed => l10n.chatVoiceRecordFailed,
  };
}
