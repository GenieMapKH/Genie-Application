import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
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
        const SizedBox(height: 16),
        _buildAvatarSection(context),
        const SizedBox(height: 24),
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
        _buildSectionTitle('End-to-End Encryption'),
        const SizedBox(height: 12),
        _buildSectionBox([
          _buildListItem(
            icon: Icons.lock_outline,
            title: 'Change Backup PIN',
            onTap: () => _handleChangeBackupPin(context, ref),
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.key_off_outlined,
            title: 'Reset E2EE Keys',
            titleColor: const Color(0xFFEF4444),
            iconColor: const Color(0xFFEF4444),
            onTap: () => _handleResetE2EEKeys(context, ref),
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

  Future<void> _handleChangeBackupPin(BuildContext context, WidgetRef ref) async {
    final initService = ref.read(e2eeInitServiceProvider);
    
    // 1. Fetch current backup to get salt/nonce/blob
    dynamic backupData;
    try {
      final response = await initService.dio.get('/chat/backup');
      backupData = response.data;
    } on DioException catch (e) {
      if (context.mounted) {
        if (e.response?.statusCode == 404) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup found. Please open Chat first to set up your keys.')),
          );
        } else if (e.response?.statusCode == 429) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Too many requests. Please try again in 15 minutes.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not fetch backup from server.')),
          );
        }
      }
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
      return;
    }

    // 2. Prompt for OLD PIN
    final oldPin = await _showPinPrompt(context, title: 'Enter Current PIN', helper: 'Enter your current 6-digit PIN to unlock the backup.');
    if (oldPin == null) return;

    // 3. Try to decrypt private key bytes
    List<int> privateKeyBytes;
    try {
      privateKeyBytes = await initService.backupService.restoreBackup(
        oldPin,
        backupData['backupSalt'],
        backupData['backupNonce'],
        backupData['backupBlob'],
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN. Failed to unlock backup.')),
        );
      }
      return;
    }

    // 4. Prompt for NEW PIN
    final newPin = await _showPinPrompt(context, title: 'Enter New PIN', helper: 'This new PIN will encrypt your existing keys.');
    if (newPin == null) return;

    // 5. Create new backup and upload
    try {
      final newBackup = await initService.backupService.createBackup(newPin, privateKeyBytes);
      await initService.dio.post('/chat/backup', data: {
        'backupBlob': newBackup['blob'],
        'backupSalt': newBackup['salt'],
        'backupNonce': newBackup['nonce'],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup PIN successfully changed.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update backup on server.')),
        );
      }
    }
  }

  Future<void> _handleResetE2EEKeys(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset E2EE Keys?'),
        content: const Text('This will generate new keys and you will LOSE ACCESS to all previous chat history. This action cannot be undone.\n\nAre you sure you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('RESET KEYS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final initService = ref.read(e2eeInitServiceProvider);
    
    // Generate new keys
    final keyPair = await initService.keyService.generateAndSaveIdentityKeyPair();
    
    if (!context.mounted) return;
    
    // Prompt for new PIN for new keys
    final newPin = await _showPinPrompt(context, title: 'Enter PIN for New Keys', helper: 'This PIN will encrypt your newly generated keys.');
    if (newPin == null) return;

    try {
      // 1. Upload new backup
      final backup = await initService.backupService.createBackup(newPin, keyPair.secretKey.extractBytes());
      await initService.dio.post('/chat/backup', data: {
        'backupBlob': backup['blob'],
        'backupSalt': backup['salt'],
        'backupNonce': backup['nonce'],
      });
      
      // 2. Upload new public key
      await initService.keyService.uploadPublicKeyIfNeeded(profile.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E2EE Keys successfully reset.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save new keys to server.')),
        );
      }
    }
  }

  Future<String?> _showPinPrompt(BuildContext context, {required String title, required String helper}) {
    String pin = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (val) => pin = val,
            decoration: InputDecoration(
              hintText: '6-digit PIN',
              helperText: helper,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, pin),
              child: const Text('Submit'),
            ),
          ],
        );
      },
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

  Widget _buildAvatarSection(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showAvatarOptions(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FEF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement camera logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from storage'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement storage picker logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sync from Google Account'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement sync logic
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
