import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/presentation/widgets/pin_prompt_dialog.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/security/presentation/screens/create_password_page.dart';
import 'package:genie/features/security/presentation/view_models/security_providers.dart';
import 'package:genie/features/security/presentation/widgets/identity_confirm_dialog.dart';
import 'package:genie/features/security/presentation/widgets/security_confirm_dialog.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/app_page_scaffold.dart';

/// What someone who forgot the PIN wants instead of it.
enum _AfterForgotPin { newPin, noPin }

/// The way back in for someone who forgot the backup PIN: the account
/// password proves they own the account, then they choose a new PIN or none.
/// An account that signs in with Google and has no password is sent to
/// create one first.
abstract final class ForgotPinActions {
  static Future<void> forgotPin(
    BuildContext context,
    WidgetRef ref, {
    required UserProfile profile,
  }) async {
    final l10n = context.l10n;
    final manager = ref.read(e2eeKeyManagerProvider);

    // Said before anything is typed: on a device without the keys, the
    // earlier chat history cannot be kept.
    final keepsHistory = await manager.holdsCurrentKeys(profile.id);
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

    final proofToken = await _provePassword(context, ref, profile);
    if (proofToken == null || !context.mounted) return;

    final choice = await _askNewPinOrNone(context);
    if (choice == null || !context.mounted) return;

    final RecoverKeysResult result;
    if (choice == _AfterForgotPin.noPin) {
      result = await manager.turnOffWithPassword(
        profile.id,
        passwordProof: proofToken,
      );
    } else {
      result = await manager.recoverWithPassword(
        profile.id,
        passwordProof: proofToken,
        askNewPin: () => showPinPrompt(
          context,
          title: l10n.pinEnterNewTitle,
          helper: l10n.forgotPinNewPinHelp,
          isNewPin: true,
        ),
      );
    }
    if (!context.mounted) return;

    switch (result) {
      case RecoverKeysResult.keptKeys:
        AppPopup.showSuccess(
          context,
          choice == _AfterForgotPin.noPin
              ? l10n.pinTurnedOff
              : l10n.forgotPinDone,
        );
      case RecoverKeysResult.newKeys:
        AppPopup.showSuccess(context, l10n.resetKeysDone);
      case RecoverKeysResult.cancelled:
        break;
      case RecoverKeysResult.proofRejected:
        AppPopup.showError(context, l10n.forgotPinProofExpired);
      case RecoverKeysResult.failed:
        AppPopup.showError(context, l10n.resetKeysFailed);
    }
  }

  /// The server's proof that the account password was typed, or null.
  static Future<String?> _provePassword(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = context.l10n;
    if (!profile.hasPassword) {
      final created = await context.pushPage<bool>(
        CreatePasswordPage(reason: l10n.forgotPinNeedsPassword),
      );
      if (created != true || !context.mounted) return null;
    }

    String? passwordProof;
    final proven = await showIdentityConfirmDialog(
      context,
      title: l10n.forgotPinPasswordTitle,
      confirmLabel: l10n.commonContinue,
      offerGoogle: false,
      isDestructive: false,
      action: (proof) async {
        final answer = await ref
            .read(accountSecurityControllerProvider)
            .provePassword(proof);
        passwordProof = answer.proofToken;
        return answer.result;
      },
    );
    return proven ? passwordProof : null;
  }

  static Future<_AfterForgotPin?> _askNewPinOrNone(BuildContext context) {
    return showDialog<_AfterForgotPin>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.forgotPinChoiceTitle),
          content: Text(l10n.forgotPinChoiceMessage),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _AfterForgotPin.noPin),
              child: Text(l10n.forgotPinChoiceNoPin),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _AfterForgotPin.newPin),
              child: Text(l10n.forgotPinChoiceNewPin),
            ),
          ],
        );
      },
    );
  }
}
