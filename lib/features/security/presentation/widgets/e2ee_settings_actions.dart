import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/presentation/widgets/pin_prompt_dialog.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/security/presentation/screens/create_password_page.dart';
import 'package:genie/features/security/presentation/view_models/security_providers.dart';
import 'package:genie/features/security/presentation/widgets/identity_confirm_dialog.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/app_page_scaffold.dart';

/// UI side of the encryption settings: shows the dialogs and messages.
/// The actual key work is done by [E2eeKeyManager].
abstract final class E2eeSettingsActions {
  static Future<void> changeBackupPin(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final result = await ref
        .read(e2eeKeyManagerProvider)
        .changeBackupPin(
          askCurrentPin: () => _askCurrentPin(context),
          askNewPin: () => showPinPrompt(
            context,
            title: l10n.pinEnterNewTitle,
            helper: l10n.pinEnterNewHelp,
            isNewPin: true,
          ),
        );
    if (!context.mounted) return;

    switch (result) {
      case ChangePinResult.changed:
        AppPopup.showSuccess(context, l10n.pinChanged);
      case ChangePinResult.cancelled:
        break;
      case ChangePinResult.noBackup:
        AppPopup.showInfo(context, l10n.pinNoBackup);
      case ChangePinResult.rateLimited:
        AppPopup.showError(context, l10n.pinLocked);
      case ChangePinResult.fetchFailed:
        AppPopup.showError(context, l10n.pinFetchFailed);
      case ChangePinResult.wrongPin:
        AppPopup.showError(context, l10n.pinWrong);
      case ChangePinResult.saveFailed:
        AppPopup.showError(context, l10n.pinSaveFailed);
    }
  }

  /// Asks for the current PIN before anything is replaced: without it,
  /// whoever holds the unlocked phone could take over the account's chats.
  static Future<void> resetKeys(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
  }) async {
    final l10n = context.l10n;
    if (!await _confirmReset(context) || !context.mounted) return;

    final result = await ref
        .read(e2eeKeyManagerProvider)
        .resetKeys(
          userId,
          askCurrentPin: () => _askCurrentPin(context),
          askNewPin: () => showPinPrompt(
            context,
            title: l10n.pinForNewKeysTitle,
            helper: l10n.pinForNewKeysHelp,
            isNewPin: true,
          ),
        );
    if (!context.mounted) return;

    switch (result) {
      case ResetKeysResult.reset:
        AppPopup.showSuccess(context, l10n.resetKeysDone);
      case ResetKeysResult.cancelled:
        break;
      case ResetKeysResult.wrongPin:
        AppPopup.showError(context, l10n.pinWrong);
      case ResetKeysResult.rateLimited:
        AppPopup.showError(context, l10n.pinLocked);
      case ResetKeysResult.fetchFailed:
        AppPopup.showError(context, l10n.pinFetchFailed);
      case ResetKeysResult.saveFailed:
        AppPopup.showError(context, l10n.resetKeysFailed);
    }
  }

  /// For someone who forgot the PIN: the account password proves they own
  /// the account instead. An account that signs in with Google and has no
  /// password is sent to create one first.
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
    final goAhead = await _confirm(
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
    final proofToken = passwordProof;
    if (!proven || proofToken == null || !context.mounted) return;

    final result = await manager.recoverWithPassword(
      profile.id,
      passwordProof: proofToken,
      askNewPin: () => showPinPrompt(
        context,
        title: l10n.pinEnterNewTitle,
        helper: l10n.forgotPinNewPinHelp,
        isNewPin: true,
      ),
    );
    if (!context.mounted) return;

    switch (result) {
      case RecoverKeysResult.keptKeys:
        AppPopup.showSuccess(context, l10n.forgotPinDone);
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

  static Future<String?> _askCurrentPin(BuildContext context) {
    return showPinPrompt(
      context,
      title: context.l10n.pinEnterCurrentTitle,
      helper: context.l10n.pinEnterCurrentHelp,
    );
  }

  static Future<bool> _confirmReset(BuildContext context) {
    final l10n = context.l10n;
    return _confirm(
      context,
      title: l10n.resetKeysConfirmTitle,
      message: l10n.resetKeysConfirmMessage,
      action: l10n.resetKeysConfirmAction,
      isDestructive: true,
    );
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    required bool isDestructive,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: dialogContext.colors.danger,
                  )
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
