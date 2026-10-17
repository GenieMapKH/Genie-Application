import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/presentation/widgets/pin_prompt_dialog.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/security/presentation/widgets/security_confirm_dialog.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

/// UI side of the encryption settings: shows the dialogs and messages.
/// The actual key work is done by [E2eeKeyManager]. A forgotten PIN is
/// handled by `ForgotPinActions`.
abstract final class E2eeSettingsActions {
  /// The backup PIN is optional; this adds one for someone who has none.
  static Future<void> setUpBackupPin(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
  }) async {
    final l10n = context.l10n;
    final result = await ref
        .read(e2eeKeyManagerProvider)
        .setUpBackupPin(
          userId,
          askNewPin: () => showPinPrompt(
            context,
            title: l10n.pinSetUpTitle,
            helper: l10n.pinSetUpHelp,
            isNewPin: true,
          ),
        );
    if (!context.mounted) return;

    switch (result) {
      case SetUpPinResult.created:
        AppPopup.showSuccess(context, l10n.pinSetUpDone);
      case SetUpPinResult.cancelled:
        break;
      case SetUpPinResult.alreadySet:
        AppPopup.showInfo(context, l10n.pinAlreadySet);
      case SetUpPinResult.keysNotReady:
        AppPopup.showInfo(context, l10n.pinKeysNotReady);
      case SetUpPinResult.rateLimited:
        AppPopup.showError(context, l10n.pinLocked);
      case SetUpPinResult.fetchFailed:
        AppPopup.showError(context, l10n.pinFetchFailed);
      case SetUpPinResult.saveFailed:
        AppPopup.showError(context, l10n.pinSaveFailed);
    }
  }

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

  /// Back to no PIN: says what is given up, then asks for the current PIN.
  static Future<void> turnOffBackupPin(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final goAhead = await showSecurityConfirmDialog(
      context,
      title: l10n.pinTurnOffConfirmTitle,
      message: l10n.pinTurnOffConfirmMessage,
      action: l10n.pinTurnOffAction,
      isDestructive: true,
    );
    if (!goAhead || !context.mounted) return;

    final result = await ref
        .read(e2eeKeyManagerProvider)
        .turnOffBackupPin(askCurrentPin: () => _askCurrentPin(context));
    if (!context.mounted) return;

    switch (result) {
      case TurnOffPinResult.turnedOff:
        AppPopup.showSuccess(context, l10n.pinTurnedOff);
      case TurnOffPinResult.cancelled:
        break;
      case TurnOffPinResult.noBackup:
        AppPopup.showInfo(context, l10n.pinNoBackup);
      case TurnOffPinResult.wrongPin:
        AppPopup.showError(context, l10n.pinWrong);
      case TurnOffPinResult.rateLimited:
        AppPopup.showError(context, l10n.pinLocked);
      case TurnOffPinResult.fetchFailed:
        AppPopup.showError(context, l10n.pinFetchFailed);
      case TurnOffPinResult.removeFailed:
        AppPopup.showError(context, l10n.pinTurnOffFailed);
    }
  }

  /// With a backup PIN, asks for it before anything is replaced: without it,
  /// whoever holds the unlocked phone could take over the account's chats.
  static Future<void> resetKeys(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
  }) async {
    final l10n = context.l10n;
    final goAhead = await showSecurityConfirmDialog(
      context,
      title: l10n.resetKeysConfirmTitle,
      message: l10n.resetKeysConfirmMessage,
      action: l10n.resetKeysConfirmAction,
      isDestructive: true,
    );
    if (!goAhead || !context.mounted) return;

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

  static Future<String?> _askCurrentPin(BuildContext context) {
    return showPinPrompt(
      context,
      title: context.l10n.pinEnterCurrentTitle,
      helper: context.l10n.pinEnterCurrentHelp,
    );
  }
}
