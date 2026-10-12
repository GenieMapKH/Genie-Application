import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:genie/app/session/sign_out.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/security/data/repositories/account_repository.dart';
import 'package:genie/features/security/presentation/view_models/account_security_controller.dart';
import 'package:genie/features/security/presentation/view_models/security_providers.dart';
import 'package:genie/features/security/presentation/widgets/identity_confirm_dialog.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/app_page_scaffold.dart';

/// Two ways to leave: deactivate (hidden until the next sign-in, nothing
/// lost) or delete (gone for good). Both ask for proof of identity first.
class AccountRemovalPage extends ConsumerWidget {
  const AccountRemovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(accountSecurityControllerProvider);
    // An account linked to Google may confirm with Google instead of a password.
    final offerGoogle =
        ref.watch(userProfileProvider).valueOrNull?.signsInWithGoogle ?? false;

    return AppPageScaffold(
      title: l10n.securityRemoveAccount,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _RemovalOption(
            icon: Icons.pause_circle_outline,
            title: l10n.removeAccountDeactivateTitle,
            body: l10n.removeAccountDeactivateBody,
            actionLabel: l10n.removeAccountDeactivateAction,
            onPressed: () => _remove(
              context,
              ref,
              title: l10n.removeAccountDeactivateTitle,
              offerGoogle: offerGoogle,
              confirmLabel: l10n.removeAccountDeactivateAction,
              doneMessage: l10n.removeAccountDeactivated,
              action: controller.deactivate,
            ),
          ),
          const SizedBox(height: 16),
          _RemovalOption(
            icon: Icons.delete_forever_outlined,
            title: l10n.removeAccountDeleteTitle,
            body: l10n.removeAccountDeleteBody,
            actionLabel: l10n.removeAccountDeleteAction,
            isDestructive: true,
            onPressed: () => _remove(
              context,
              ref,
              title: l10n.removeAccountDeleteTitle,
              offerGoogle: offerGoogle,
              confirmLabel: l10n.removeAccountDeleteConfirmAction,
              doneMessage: l10n.removeAccountDeleted,
              action: controller.delete,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String confirmLabel,
    required String doneMessage,
    required bool offerGoogle,
    required Future<AccountActionResult> Function(IdentityProof proof) action,
  }) async {
    final removed = await showIdentityConfirmDialog(
      context,
      title: title,
      confirmLabel: confirmLabel,
      offerGoogle: offerGoogle,
      action: action,
    );
    if (!removed || !context.mounted) return;

    // The server has ended every session: forget this one and start over.
    AppPopup.showSuccess(context, doneMessage);
    await ref.read(signOutProvider)();
    if (context.mounted) context.go('/');
  }
}

class _RemovalOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _RemovalOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final emphasis = isDestructive ? colors.danger : colors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive ? colors.dangerBorder : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: emphasis),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: emphasis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: emphasis,
              side: BorderSide(
                color: isDestructive ? colors.dangerBorder : colors.border,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
