import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:tilomnov/features/safety/presentation/view_models/block_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

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
  final confirmed = await AppDialog.show<bool>(
    context,
    builder: (_) => AppDialog(
      icon: blocked ? Icons.block_rounded : Icons.lock_open_rounded,
      tone: blocked ? AppDialogTone.danger : AppDialogTone.neutral,
      title: blocked
          ? l10n.blockConfirmTitle(name)
          : l10n.unblockConfirmTitle(name),
      message: blocked ? l10n.blockConfirmMessage : l10n.unblockConfirmMessage,
      primaryLabel: blocked ? l10n.blockAction : l10n.unblockAction,
      secondaryLabel: l10n.commonCancel,
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
    showFailure(context, fallback: l10n.blockFailed);
  }
}
