import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/shared/widgets/app_header_bar.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/profile/presentation/widgets/profile_info_section.dart';

class UserProfilePage extends ConsumerWidget {
  final bool isEmbedded;
  final VoidCallback? onBackPressed;

  const UserProfilePage({
    super.key,
    this.isEmbedded = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeaderBar(title: 'Account', onBackPressed: onBackPressed),

            if (profileAsync.hasError &&
                profileAsync.hasValue &&
                !profileAsync.isLoading)
              _buildOfflineWarning(),

            const SizedBox(height: 16),
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
                  error: (error, _) => _buildErrorState(ref),
                  data: (profile) => ProfileInfoSection(profile: profile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineWarning() {
    return Container(
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
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return CustomScrollView(
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
    );
  }
}
