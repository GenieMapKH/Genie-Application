import 'package:tilomnov/features/chat/models/chat_message_action_problem.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';

/// Why a message was not edited or deleted, as the snackbar says it.
String chatMessageActionProblemText(
  AppLocalizations l10n,
  ChatMessageActionProblem problem,
) {
  return switch (problem) {
    ChatMessageActionProblem.editTooLate => l10n.chatEditTooLate,
    ChatMessageActionProblem.failed => l10n.chatActionFailed,
  };
}
