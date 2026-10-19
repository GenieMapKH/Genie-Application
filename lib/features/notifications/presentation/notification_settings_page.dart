import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/device/system_settings.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/notifications/models/notification_preferences.dart';
import 'package:genie/features/notifications/providers/notification_preferences_provider.dart';
import 'package:genie/features/settings/providers/app_settings_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/layout/app_page_scaffold.dart';
import 'package:genie/shared/widgets/lists/settings_list.dart';

/// Which notifications the user wants. Security alerts and calls cannot be
/// turned off here, only in the phone's settings.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final preferences = ref.watch(notificationPreferencesProvider);
    final allowed = ref.watch(notificationsAllowedProvider).valueOrNull;

    return AppPageScaffold(
      title: l10n.notificationsTitle,
      child: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(
          onRetry: () =>
              ref.read(notificationPreferencesProvider.notifier).load(),
        ),
        data: (preferences) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            if (allowed == false) ...[
              const _BlockedNotice(),
              const SizedBox(height: 20),
            ],
            _Switches(preferences: preferences),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.notificationsAlwaysOn,
                style: TextStyle(fontSize: 13, color: context.colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Switches extends ConsumerWidget {
  final NotificationPreferences preferences;

  const _Switches({required this.preferences});

  Future<void> _change(
    BuildContext context,
    WidgetRef ref, {
    bool? chatMessages,
    bool? promotions,
  }) async {
    final saved = await ref
        .read(notificationPreferencesProvider.notifier)
        .change(chatMessages: chatMessages, promotions: promotions);
    if (!saved && context.mounted) {
      AppPopup.showError(context, context.l10n.notificationsSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SettingsSection(
      children: [
        SettingsSwitchRow(
          icon: Icons.chat_bubble_outline,
          title: l10n.notificationsChatTitle,
          subtitle: l10n.notificationsChatHelp,
          value: preferences.chatMessages,
          onChanged: (on) => _change(context, ref, chatMessages: on),
        ),
        // Only Android shows what a message says: the other platforms get
        // the generic notification.
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          SettingsSwitchRow(
            icon: Icons.text_snippet_outlined,
            title: l10n.notificationsShowTextTitle,
            subtitle: l10n.notificationsShowTextHelp,
            value: ref.watch(showNotificationTextProvider),
            onChanged: (on) =>
                ref.read(showNotificationTextProvider.notifier).select(on),
          ),
        SettingsSwitchRow(
          icon: Icons.local_offer_outlined,
          title: l10n.notificationsPromotionsTitle,
          subtitle: l10n.notificationsPromotionsHelp,
          value: preferences.promotions,
          onChanged: (on) => _change(context, ref, promotions: on),
        ),
      ],
    );
  }
}

/// The phone itself blocks this app's notifications: no switch here helps.
class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.dangerSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dangerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off_outlined, color: colors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.notificationsBlockedTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onDangerSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.notificationsBlockedHelp,
            style: TextStyle(fontSize: 13, color: colors.onDangerSoft),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: openAppSystemSettings,
            child: Text(l10n.openSystemSettings),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.textHint),
          const SizedBox(height: 16),
          Text(
            context.l10n.notificationsLoadFailed,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: colors.textMuted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
        ],
      ),
    );
  }
}
