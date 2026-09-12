import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/widgets/profile_edit_dialog.dart';

class ProfileInfoSection extends ConsumerWidget {
  final UserProfile profile;

  const ProfileInfoSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        _buildSectionTitle('Personal information'),
        const SizedBox(height: 12),
        _buildSectionBox([
          _buildListItem(
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
          _buildDivider(),
          _buildListItem(
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
          _buildDivider(),
          _buildListItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: profile.email ?? 'Not set',
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionTitle('Manage account'),
        const SizedBox(height: 12),
        _buildSectionBox([
          _buildListItem(
            icon: Icons.no_accounts_outlined,
            title: 'Deactivate or delete account',
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & cookies',
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.language_outlined,
            title: 'Language',
            value: 'English',
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.star_border,
            title: 'Subscription Plan',
            value: 'Free',
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.logout_outlined,
            title: 'Sign out',
            titleColor: const Color(0xFF5B5FEF),
            iconColor: const Color(0xFF5B5FEF),
            hideChevron: true,
            onTap: () => _handleLogout(context, ref),
          ),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();

    // Reset bottom navigation tab back to Explore/Home (index 0)
    ref.read(mainNavProvider.notifier).resetToHome();

    // Clear cached data in providers
    ref.invalidate(userProfileProvider);
    ref.invalidate(propertiesProvider);
    ref.invalidate(publicPropertiesProvider);

    if (context.mounted) {
      context.go('/');
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildSectionBox(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? value,
    Color? titleColor,
    Color? iconColor,
    bool hideChevron = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? const Color(0xFF6B7280)),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor ?? const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            if (value != null) const SizedBox(width: 8),
            if (!hideChevron)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFD1D5DB),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF3F4F6),
      indent: 52,
    );
  }
}
