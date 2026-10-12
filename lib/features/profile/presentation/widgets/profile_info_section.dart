import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:genie/features/profile/presentation/widgets/profile_edit_dialog.dart';
import 'package:genie/features/profile/presentation/widgets/profile_section_widgets.dart';
import 'package:genie/features/profile/presentation/widgets/profile_security_actions.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

/// The profile tab: personal info, encryption settings and account actions.
class ProfileInfoSection extends ConsumerWidget {
  final UserProfile profile;

  const ProfileInfoSection({super.key, required this.profile});

  static const _danger = Color(0xFFEF4444);
  static const _accent = Color(0xFF5B5FEF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        const SizedBox(height: 16),
        ProfileAvatar(profile: profile),
        const SizedBox(height: 24),
        const ProfileSectionTitle('Personal information'),
        const SizedBox(height: 12),
        _personalInfo(context),
        const SizedBox(height: 24),
        const ProfileSectionTitle('End-to-End Encryption'),
        const SizedBox(height: 12),
        _encryption(context, ref),
        const SizedBox(height: 24),
        const ProfileSectionTitle('Manage account'),
        const SizedBox(height: 12),
        _account(context, ref),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _personalInfo(BuildContext context) {
    return ProfileSectionBox(
      children: [
        ProfileListItem(
          icon: Icons.person_outline,
          title: 'Name',
          value: profile.displayName,
          onTap: () => ProfileEditDialog.show(
            context,
            'Username',
            'username',
            profile.username,
          ),
        ),
        const ProfileListDivider(),
        ProfileListItem(
          icon: Icons.phone_outlined,
          title: 'Phone number',
          value: profile.phone ?? 'Not set',
          onTap: () => ProfileEditDialog.show(
            context,
            'Phone Number',
            'phone',
            profile.phone,
          ),
        ),
        const ProfileListDivider(),
        ProfileListItem(
          icon: Icons.email_outlined,
          title: 'Email',
          value: profile.email ?? 'Not set',
        ),
      ],
    );
  }

  Widget _encryption(BuildContext context, WidgetRef ref) {
    return ProfileSectionBox(
      children: [
        ProfileListItem(
          icon: Icons.lock_outline,
          title: 'Change Backup PIN',
          onTap: () => ProfileSecurityActions.changeBackupPin(context, ref),
        ),
        const ProfileListDivider(),
        ProfileListItem(
          icon: Icons.key_off_outlined,
          title: 'Reset E2EE Keys',
          titleColor: _danger,
          iconColor: _danger,
          onTap: () => ProfileSecurityActions.resetKeys(
            context,
            ref,
            userId: profile.id,
          ),
        ),
      ],
    );
  }

  Widget _account(BuildContext context, WidgetRef ref) {
    return ProfileSectionBox(
      children: [
        const ProfileListItem(
          icon: Icons.no_accounts_outlined,
          title: 'Deactivate or delete account',
        ),
        const ProfileListDivider(),
        const ProfileListItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy & cookies',
        ),
        const ProfileListDivider(),
        const ProfileListItem(
          icon: Icons.language_outlined,
          title: 'Language',
          value: 'English',
        ),
        const ProfileListDivider(),
        const ProfileListItem(
          icon: Icons.star_border,
          title: 'Subscription Plan',
          value: 'Free',
        ),
        const ProfileListDivider(),
        ProfileListItem(
          icon: Icons.logout_outlined,
          title: 'Sign out',
          titleColor: _accent,
          iconColor: _accent,
          hideChevron: true,
          onTap: () => _signOut(context, ref),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).logout();

    // Back to the Explore tab, and drop everything cached for this user.
    ref.read(mainNavProvider.notifier).resetToHome();
    ref.invalidate(userProfileProvider);
    ref.invalidate(propertiesProvider);
    ref.invalidate(publicPropertiesProvider);
    // Closes the chat connection now instead of when the profile reloads.
    ref.invalidate(chatSocketServiceProvider);

    if (context.mounted) context.go('/');
  }
}
