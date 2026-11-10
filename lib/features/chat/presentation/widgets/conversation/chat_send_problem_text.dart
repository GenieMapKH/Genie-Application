import 'package:tilomnov/features/chat/data/chat_attachment_service.dart';
import 'package:tilomnov/features/chat/models/chat_send_problem.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// Why a message was not sent, as the snackbar says it.
String chatSendProblemText(AppLocalizations l10n, ChatSendProblem problem) {
  return switch (problem) {
    ChatSendProblem.signedOut => l10n.chatSendSignedOut,
    ChatSendProblem.noConnection => l10n.chatSendNoConnection,
    ChatSendProblem.rejected => l10n.chatSendRejected,
    ChatSendProblem.tooFast => l10n.chatSendTooFast,
    ChatSendProblem.blocked => l10n.chatSendBlocked,
    ChatSendProblem.fileTooLarge => l10n.chatSendFileTooLarge(
      ChatAttachmentService.maxBytes ~/ (1024 * 1024),
    ),
    ChatSendProblem.uploadFailed => failureMessage(
      l10n,
      fallback: l10n.chatSendUploadFailed,
    ),
    ChatSendProblem.failed => failureMessage(
      l10n,
      fallback: l10n.chatSendFailed,
    ),
  };
}
