import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/security/presentation/screens/account_removal_page.dart';
import 'package:genie/features/security/presentation/screens/change_password_page.dart';
import 'package:genie/features/security/presentation/screens/create_password_page.dart';
import 'package:genie/features/security/presentation/screens/devices_page.dart';
import 'package:genie/features/security/presentation/widgets/e2ee_settings_actions.dart';
import 'package:genie/features/security/presentation/widgets/forgot_pin_actions.dart';
import 'package:genie/features/security/presentation/widgets/info_note.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/app_page_scaffold.dart';
import 'package:genie/shared/widgets/settings_list.dart';

/// Everything that protects the account: chat encryption keys, the password,
/// the devices signed in, and deactivating or deleting the account.
class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Keys are kept per account, so their rows wait for the profile.
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return AppPageScaffold(
      title: l10n.securityTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          SettingsSectionTitle(l10n.securitySectionEncryption),
          InfoNote(l10n.securityPinOptionalNote),
          const SizedBox(height: 12),
          SettingsSection(
            children: [
              SettingsRow(
                icon: Icons.lock_open_outlined,
                title: l10n.securitySetUpPin,
                onTap: profile == null
                    ? null
                    : () => E2eeSettingsActions.setUpBackupPin(
                        context,
                        ref,
                        userId: profile.id,
                      ),
              ),
              SettingsRow(
                icon: Icons.lock_outline,
                title: l10n.securityChangePin,
                onTap: () => E2eeSettingsActions.changeBackupPin(context, ref),
              ),
              SettingsRow(
                icon: Icons.help_outline,
                title: l10n.securityForgotPin,
                onTap: profile == null
                    ? null
                    : () => ForgotPinActions.forgotPin(
                        context,
                        ref,
                        profile: profile,
                      ),
              ),
              SettingsRow(
                icon: Icons.no_encryption_outlined,
                title: l10n.securityTurnOffPin,
                onTap: () => E2eeSettingsActions.turnOffBackupPin(context, ref),
              ),
              SettingsRow(
                icon: Icons.key_off_outlined,
                title: l10n.securityResetKeys,
                isDestructive: true,
                onTap: profile == null
                    ? null
                    : () => E2eeSettingsActions.resetKeys(
                        context,
                        ref,
                        userId: profile.id,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSectionTitle(l10n.securitySectionSignIn),
          SettingsSection(
            children: [
              // An account that signs in with Google has no password to
              // change until it creates one.
              if (profile?.hasPassword ?? true)
                SettingsRow(
                  icon: Icons.password_outlined,
                  title: l10n.securityChangePassword,
                  onTap: () => context.pushPage(const ChangePasswordPage()),
                )
              else
                SettingsRow(
                  icon: Icons.password_outlined,
                  title: l10n.securityCreatePassword,
                  onTap: () => context.pushPage(const CreatePasswordPage()),
                ),
              SettingsRow(
                icon: Icons.devices_outlined,
                title: l10n.securityDevices,
                onTap: () => context.pushPage(const DevicesPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSectionTitle(l10n.securitySectionAccount),
          SettingsSection(
            children: [
              SettingsRow(
                icon: Icons.no_accounts_outlined,
                title: l10n.securityRemoveAccount,
                onTap: () => context.pushPage(const AccountRemovalPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
