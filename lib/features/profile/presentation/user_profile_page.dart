import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/services/auth_service.dart';
import 'package:genie/features/profile/data/user_providers.dart';
import 'package:genie/features/profile/data/user_repository.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const UserProfilePage({
    super.key,
    this.isEmbedded = false,
    this.onBackPressed,
  });

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 42),
            _buildHeader(),
            const SizedBox(height: 32),
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF5B5FEF)),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load profile',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.invalidate(userProfileProvider),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5B5FEF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (profile) => _buildProfileContent(profile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        _buildSectionTitle('Personal information'),
        const SizedBox(height: 12),
        _buildSectionBox([
          _buildListItem(
            icon: Icons.person_outline,
            title: 'Name',
            value: profile.displayName,
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.phone_outlined,
            title: 'Phone number',
            value: profile.phone ?? 'Not set',
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
            onTap: _handleLogout,
          ),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    if (mounted) {
      context.go('/');
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            'Account',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
