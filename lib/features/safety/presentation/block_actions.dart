import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:genie/features/safety/presentation/view_models/block_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

/// Blocks [userId] after saying what that does, or unblocks them, from
/// wherever the choice is offered. A guest is asked to sign in first.
Future<void> setBlocked(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String name,
  required bool blocked,
}) async {
  if (!requireSignIn(context, ref)) return;
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        blocked ? l10n.blockConfirmTitle(name) : l10n.unblockConfirmTitle(name),
      ),
      content: Text(
        blocked ? l10n.blockConfirmMessage : l10n.unblockConfirmMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: blocked
              ? TextButton.styleFrom(
                  foregroundColor: dialogContext.colors.danger,
                )
              : null,
          child: Text(blocked ? l10n.blockAction : l10n.unblockAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final done = await ref
      .read(blockStatusProvider(userId).notifier)
      .setBlocked(blocked);
  if (!context.mounted) return;
  if (done) {
    AppPopup.showSuccess(
      context,
      blocked ? l10n.blockDone(name) : l10n.unblockDone(name),
    );
  } else {
    AppPopup.showError(context, l10n.blockFailed);
  }
}
