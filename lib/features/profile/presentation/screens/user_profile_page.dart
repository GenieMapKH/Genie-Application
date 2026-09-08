import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';

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
            if (profileAsync.hasError && profileAsync.hasValue && !profileAsync.isLoading)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are offline, Please connect to internet for updates.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5B5FEF),
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  try {
                    await ref.read(userProfileProvider.future);
                  } catch (_) {}
                },
                child: profileAsync.when(
                  skipLoadingOnReload: true,
                  skipError: true,
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5B5FEF)),
                  ),
                  error: (error, _) => CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
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
                      ),
                    ],
                  ),
                  data: (profile) => _buildProfileContent(profile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile) {
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
            onTap: () =>
                _showEditDialog('Username', 'username', profile.username),
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.phone_outlined,
            title: 'Phone number',
            value: profile.phone ?? 'Not set',
            onTap: () =>
                _showEditDialog('Phone Number', 'phone', profile.phone),
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

    // Clear cached data in providers
    ref.invalidate(userProfileProvider);
    ref.invalidate(propertiesProvider);
    ref.invalidate(publicPropertiesProvider);

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

  Future<void> _showEditDialog(
    String title,
    String fieldKey,
    String? initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue);
    String? errorMessage;
    bool isSaving = false;

    final isPhone = fieldKey == 'phone';
    final iconData = isPhone ? Icons.phone_android : Icons.person_outline;
    final hintText = isPhone ? 'e.g. +855 12 345 678' : 'e.g. john_doe';
    final description = isPhone
        ? 'Update your phone number. This may be used for account recovery and notifications.'
        : 'Choose a unique username. This will be visible to other users.';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(iconData, color: const Color(0xFF5B5FEF), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Update $title',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: controller,
                    keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: title,
                      hintText: hintText,
                      errorText: errorMessage,
                      errorMaxLines: 2,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF5B5FEF), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final newValue = controller.text.trim();
                                  if (newValue.isEmpty || newValue == initialValue) {
                                    Navigator.pop(context);
                                    return;
                                  }

                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text('Confirm Change', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                      content: Text(
                                        'Are you sure you want to change your ${title.toLowerCase()} to "$newValue"?',
                                        style: GoogleFonts.inter(color: const Color(0xFF4B5563)),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('No, cancel', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF5B5FEF),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text('Yes, save', style: GoogleFonts.inter(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;

                                  setState(() {
                                    errorMessage = null;
                                    isSaving = true;
                                  });

                                  try {
                                    final repo = ref.read(userRepositoryProvider);
                                    if (fieldKey == 'username') {
                                      await repo.updateProfile(username: newValue);
                                    } else if (fieldKey == 'phone') {
                                      await repo.updateProfile(phone: newValue);
                                    }
                                    if (context.mounted) {
                                      ref.invalidate(userProfileProvider);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$title updated successfully!'),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } on DioException catch (e) {
                                    if (e.response?.statusCode == 409) {
                                      setState(() {
                                        errorMessage = e.response?.data?['message'] ??
                                            'This ${title.toLowerCase()} is taken.';
                                        isSaving = false;
                                      });
                                    } else {
                                      setState(() {
                                        errorMessage = 'An error occurred. Please try again.';
                                        isSaving = false;
                                      });
                                    }
                                  } catch (e) {
                                    setState(() {
                                      errorMessage = 'An error occurred. Please try again.';
                                      isSaving = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B5FEF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }
}
