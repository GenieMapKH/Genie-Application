import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/auth/presentation/view_models/after_password_sign_in.dart';
import 'package:genie/features/chat/data/chat_backup_repository.dart';
import 'package:genie/features/chat/presentation/widgets/pin_prompt_dialog.dart';
import 'package:genie/features/chat/providers/chat_password_lock.dart';
import 'package:genie/l10n/l10n.dart';

/// After a password sign-in, unlocks the chat keys with that password, so
/// the chats of an account are on every device it signs in on.
///
/// An account that still has a backup PIN is asked for it one last time
/// (only on a device without its keys); the password protects the chats
/// from then on.
AfterPasswordSignIn chatKeysAfterSignIn(Ref ref) {
  return (context, password) async {
    await ref
        .read(chatPasswordLockProvider)
        .lockWith(
          password,
          askPin: (lock) async {
            if (lock != BackupLock.pin || !context.mounted) return null;
            return showPinPrompt(
              context,
              title: context.l10n.chatPinLastTimeTitle,
              helper: context.l10n.chatPinLastTimeHelp,
            );
          },
        );
  };
}
