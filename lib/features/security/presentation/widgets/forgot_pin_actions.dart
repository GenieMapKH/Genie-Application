import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/presentation/widgets/account_password_prompt.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/security/presentation/screens/create_password_page.dart';
import 'package:genie/features/security/presentation/widgets/security_confirm_dialog.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/app_page_scaffold.dart';

/// The way back in for someone who forgot the backup PIN. Only an account
/// that signs in with Google alone has a PIN, so the answer is an account
/// password: it protects the chats from then on, instead of a PIN.
///
/// Creating it locks the keys this device holds with it, so no history is
/// lost ([AccountSecurityController.createPassword]). A device without the
/// keys cannot open them without the PIN: new keys are made, locked with
/// the new password.
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

    final created = await context.pushPage<bool>(
      CreatePasswordPage(reason: l10n.forgotPinNeedsPassword),
    );
    if (created != true || !context.mounted) return;

    if (keepsHistory) {
      AppPopup.showSuccess(context, l10n.forgotPinNowPassword);
      return;
    }
    await _startOver(context, ref, profile.id);
  }

  /// New keys, locked with the password just created.
  static Future<void> _startOver(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final l10n = context.l10n;
    final password = await showAccountPasswordPrompt(
      context,
      title: l10n.chatPasswordTitle,
      helper: l10n.resetKeysPasswordHelp,
    );
    if (password == null || !context.mounted) return;

    final result = await ref
        .read(e2eeSetupServiceProvider)
        .startOver(userId, password);
    if (!context.mounted) return;

    switch (result) {
      case E2eeSetupResult.ready:
        AppPopup.showSuccess(context, l10n.resetKeysDone);
      case E2eeSetupResult.wrongPassword:
        AppPopup.showError(context, l10n.chatPasswordWrong);
      case E2eeSetupResult.rateLimited:
        AppPopup.showError(context, l10n.chatPasswordTooManyTries);
      default:
        AppPopup.showError(context, l10n.resetKeysFailed);
    }
  }
}
