import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tilomnov/app/session/sign_out.dart';
import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/screens/personal_info_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:tilomnov/features/security/presentation/screens/security_page.dart';
import 'package:tilomnov/features/notifications/presentation/notification_settings_page.dart';
import 'package:tilomnov/features/settings/presentation/widgets/preference_rows.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/page_load_failure.dart';
import 'package:tilomnov/shared/widgets/feedback/refresh_outcome.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/lists/settings_list.dart';
import 'package:tilomnov/features/search/presentation/screens/saved_searches_page.dart';

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

  /// Pull-to-refresh. A profile shown stays; says so when there is no
  /// internet (it is then the one kept from before) or it failed.
  Future<void> _refresh() async {
    final shownBefore = ref.read(userProfileProvider).hasValue;
    ref.invalidate(userProfileProvider);
    var ok = true;
    try {
      await ref.read(userProfileProvider.future);
    } catch (e) {
      // The error state is rendered from the provider itself.
      AppLogger.error('Profile refresh failed', e);
      ok = false;
    }
    if (!shownBefore || !mounted) return;
    showRefreshOutcome(
      context,
      ok: ok,
      failedMessage: context.l10n.accountLoadFailed,
      onRetry: _refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    return AppPageScaffold(
      title: context.l10n.accountTitle,
      onBackPressed: widget.onBackPressed,
      // The menu carries on behind a floating navigation bar.
      extendsToBottom: true,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: context.colors.accent,
              onRefresh: _refresh,
              // A profile from before stays up while it is refreshed; with
              // none, a retry shows the spinner rather than the old error.
              // No profile and no error: signing out, about to leave.
              child: profile != null
                  ? _AccountMenu(profile: profile)
                  : profileAsync.hasError &&
                        !profileAsync.isLoading &&
                        !_retryingOnOpen
                  ? PageLoadFailure(
                      error: profileAsync.error,
                      message: context.l10n.accountLoadFailed,
                      onRetry: () => ref.invalidate(userProfileProvider),
                    )
                  : const Center(child: CircularProgressIndicator()),
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
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        40 + MediaQuery.paddingOf(context).bottom,
      ),
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
        SettingsSection(
          children: [
            const AppearanceRow(),
            const LanguageRow(),
            SettingsRow(
              icon: Icons.notifications_none_outlined,
              title: l10n.notificationsTitle,
              onTap: () => context.pushPage(const NotificationSettingsPage()),
            ),
            SettingsRow(
              icon: Icons.travel_explore,
              title: l10n.savedSearchesTitle,
              onTap: () => context.pushPage(const SavedSearchesPage()),
            ),
          ],
        ),
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
