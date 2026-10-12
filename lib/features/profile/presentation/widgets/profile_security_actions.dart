import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/presentation/widgets/pin_prompt_dialog.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';

/// UI side of the encryption settings: shows the dialogs and messages.
/// The actual key work is done by [E2eeKeyManager].
abstract final class ProfileSecurityActions {
  static Future<void> changeBackupPin(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await ref
        .read(e2eeKeyManagerProvider)
        .changeBackupPin(
          askCurrentPin: () => showPinPrompt(
            context,
            title: 'Enter Current PIN',
            helper: 'Enter your current 6-digit PIN to unlock the backup.',
          ),
          askNewPin: () => showPinPrompt(
            context,
            title: 'Enter New PIN',
            helper: 'This new PIN will encrypt your existing keys.',
            isNewPin: true,
          ),
        );

    if (!context.mounted) return;
    _showMessage(context, switch (result) {
      ChangePinResult.changed => 'Backup PIN successfully changed.',
      ChangePinResult.noBackup =>
        'No backup found. Please open Chat first to set up your keys.',
      ChangePinResult.rateLimited =>
        'Too many wrong PINs. The backup is locked; try again later.',
      ChangePinResult.fetchFailed => 'Could not fetch backup from server.',
      ChangePinResult.wrongPin =>
        'Incorrect PIN. After 5 wrong tries the backup locks for a while.',
      ChangePinResult.saveFailed => 'Failed to update backup on server.',
      ChangePinResult.cancelled => null,
    });
  }

  static Future<void> resetKeys(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
  }) async {
    if (!await _confirmReset(context)) return;
    if (!context.mounted) return;

    final result = await ref
        .read(e2eeKeyManagerProvider)
        .resetKeys(
          userId,
          askNewPin: () => showPinPrompt(
            context,
            title: 'Enter PIN for New Keys',
            helper: 'This PIN will encrypt your newly generated keys.',
            isNewPin: true,
          ),
        );

    if (!context.mounted) return;
    _showMessage(context, switch (result) {
      ResetKeysResult.reset => 'E2EE Keys successfully reset.',
      ResetKeysResult.saveFailed => 'Failed to save new keys to server.',
      ResetKeysResult.cancelled => null,
    });
  }

  static Future<bool> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset E2EE Keys?'),
        content: const Text(
          'This will generate new keys and you will LOSE ACCESS to all '
          'previous chat history. This action cannot be undone.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET KEYS'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static void _showMessage(BuildContext context, String? message) {
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
