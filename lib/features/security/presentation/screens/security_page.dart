import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/safety/presentation/screens/blocked_accounts_page.dart';
import 'package:tilomnov/features/security/presentation/screens/account_removal_page.dart';
import 'package:tilomnov/features/security/presentation/screens/change_password_page.dart';
import 'package:tilomnov/features/security/presentation/screens/create_password_page.dart';
import 'package:tilomnov/features/security/presentation/screens/devices_page.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/lists/settings_list.dart';

/// Everything that protects the account: chat encryption keys, the password,
/// the devices signed in, the accounts blocked, and deactivating or deleting
/// the account.
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
              SettingsRow(
                icon: Icons.block,
                title: l10n.blockedAccountsTitle,
                onTap: () => context.pushPage(const BlockedAccountsPage()),
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
