import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:genie/app/session/sign_out.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/screens/personal_info_page.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:genie/features/security/presentation/screens/security_page.dart';
import 'package:genie/features/settings/presentation/widgets/preference_rows.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/app_page_scaffold.dart';
import 'package:genie/shared/widgets/settings_list.dart';

/// The "User" tab: who is signed in, and the way into every account setting.
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
  /// True from opening until the retry of an earlier failure has started.
  bool _retryingOnOpen = false;

  /// Whether the page was on screen at the last check. The page is kept
  /// while another tab is shown, and [TickerMode] says when it is back.
  bool _wasShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.valuesOf(context).enabled;
    if (shown && !_wasShown) _retryEarlierFailure();
    _wasShown = shown;
  }

  /// The provider keeps a failure (the app woke up offline, say) until it is
  /// asked again. Opening the screen asks again, so it never greets the user
  /// with an error from earlier.
  void _retryEarlierFailure() {
    _retryingOnOpen = ref.read(userProfileProvider).hasError;
    if (!_retryingOnOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _retryingOnOpen = false);
      ref.invalidate(userProfileProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    // A refresh failed but the profile from before is still shown.
    final showsStaleProfile =
        profileAsync.hasError &&
        profileAsync.hasValue &&
        !profileAsync.isLoading;

    return AppPageScaffold(
      title: context.l10n.accountTitle,
      onBackPressed: widget.onBackPressed,
      child: Column(
        children: [
          if (showsStaleProfile) const _OfflineWarning(),
          Expanded(
            child: RefreshIndicator(
              color: context.colors.accent,
              onRefresh: () async {
                ref.invalidate(userProfileProvider);
                try {
                  await ref.read(userProfileProvider.future);
                } catch (e) {
                  // The error state is rendered from the provider itself.
                  AppLogger.error('Profile refresh failed', e);
                }
              },
              // A profile from before stays up while it is refreshed; with
              // none, a retry shows the spinner rather than the old error.
              child: profile != null
                  ? _AccountMenu(profile: profile)
                  : profileAsync.isLoading || _retryingOnOpen
                  ? const Center(child: CircularProgressIndicator())
                  : _LoadError(
                      onRetry: () => ref.invalidate(userProfileProvider),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  final UserProfile profile;

  const _AccountMenu({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        ProfileHeader(profile: profile),
        const SizedBox(height: 28),
        SettingsSectionTitle(l10n.accountSectionAccount),
        SettingsSection(
          children: [
            SettingsRow(
              icon: Icons.person_outline,
              title: l10n.accountPersonalInfo,
              onTap: () => context.pushPage(const PersonalInfoPage()),
            ),
            SettingsRow(
              icon: Icons.shield_outlined,
              title: l10n.accountSecurity,
              onTap: () => context.pushPage(const SecurityPage()),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionTitle(l10n.accountSectionPreferences),
        const SettingsSection(children: [AppearanceRow(), LanguageRow()]),
        const SizedBox(height: 24),
        SettingsSectionTitle(l10n.accountSectionMore),
        SettingsSection(
          children: [
            SettingsRow(
              icon: Icons.star_border,
              title: l10n.accountSubscription,
              value: l10n.accountSubscriptionFree,
            ),
            SettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: l10n.accountPrivacy,
            ),
            SettingsRow(
              icon: Icons.logout_outlined,
              title: l10n.accountSignOut,
              isAction: true,
              onTap: () async {
                await ref.read(signOutProvider)();
                if (context.mounted) context.go('/');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _OfflineWarning extends StatelessWidget {
  const _OfflineWarning();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.dangerSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.dangerBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: colors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.commonOffline,
              style: TextStyle(fontSize: 12, color: colors.onDangerSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable, so pull-to-refresh still works while the error is shown.
class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.textHint),
                const SizedBox(height: 16),
                Text(
                  l10n.accountLoadFailed,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    l10n.commonRetry,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
