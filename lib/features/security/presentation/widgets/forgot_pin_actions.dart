import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:tilomnov/features/chat/presentation/widgets/pin/account_password_prompt.dart';
import 'package:tilomnov/features/chat/presentation/widgets/pin/pin_prompt_dialog.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/security/presentation/screens/create_password_page.dart';
import 'package:tilomnov/features/security/presentation/widgets/security_confirm_dialog.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// The way back in for someone who forgot the chat PIN: the account
/// password proves it is them, then they choose a new PIN. An account that
/// signs in with Google alone creates a password first.
///
/// A device that holds the chat keys keeps them under the new PIN, so no
/// history is lost. One without them cannot open them without the old PIN:
/// new keys are made, and earlier messages can no longer be read.
abstract final class ForgotPinActions {
  static Future<void> forgotPin(
    BuildContext context,
    WidgetRef ref, {
    required UserProfile profile,
  }) async {
    final l10n = context.l10n;

    // Said before anything is typed: on a device without the keys, the
    // earlier chat history cannot be kept.
    final keepsHistory = await ref
        .read(e2eeKeyManagerProvider)
        .holdsCurrentKeys(profile.id);
    if (!context.mounted) return;
    final goAhead = await showSecurityConfirmDialog(
      context,
      title: l10n.forgotPinTitle,
      message: keepsHistory
          ? l10n.forgotPinKeepsHistory
          : l10n.forgotPinLosesHistory,
      action: l10n.commonContinue,
      isDestructive: !keepsHistory,
    );
    if (!goAhead || !context.mounted) return;

    if (!profile.hasPassword) {
      final created = await context.pushPage<bool>(
        CreatePasswordPage(reason: l10n.forgotPinNeedsPassword),
      );
      if (created != true || !context.mounted) return;
    }

    final password = await showAccountPasswordPrompt(
      context,
      title: l10n.chatPasswordTitle,
      helper: l10n.forgotPinPasswordHelp,
    );
    if (password == null || !context.mounted) return;

    final result = await ref
        .read(e2eeKeyManagerProvider)
        .recoverWithPassword(
          profile.id,
          password: password,
          askNewPin: () => showPinPrompt(
            context,
            title: l10n.pinEnterNewTitle,
            helper: l10n.pinSetUpHelp,
            isNewPin: true,
          ),
        );
    if (!context.mounted) return;

    switch (result) {
      case RecoverPinResult.recovered:
        AppPopup.showSuccess(context, l10n.forgotPinRecovered);
      case RecoverPinResult.startedOver:
        AppPopup.showSuccess(context, l10n.resetKeysDone);
      case RecoverPinResult.cancelled:
        break;
      case RecoverPinResult.wrongPassword:
        AppPopup.showError(context, l10n.chatPasswordWrong);
      case RecoverPinResult.rateLimited:
        AppPopup.showError(context, l10n.chatPasswordTooManyTries);
      case RecoverPinResult.failed:
        showFailure(context, fallback: l10n.pinSaveFailed);
    }
  }
}
