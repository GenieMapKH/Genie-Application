import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'admin_dashboard_provider.dart';
import 'admin_rotation_action.dart';
import 'admin_service_card.dart';

class AdminRotationPanel extends ConsumerWidget {
  const AdminRotationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rotation = ref.watch(adminRotationProvider);
    return AdminServiceCard(
      icon: Icons.key_rounded,
      title: 'Infisical',
      onRefresh: () => ref.invalidate(adminRotationProvider),
      refreshing: rotation.isLoading && rotation.hasValue,
      refreshFailed: rotation.hasError && rotation.hasValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rotation.when(
            skipLoadingOnReload: true,
            skipError: true,
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Rotation status unavailable'),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data.status == 'ok'
                      ? 'Connected${data.environment == null ? '' : ' ? ${data.environment}'}'
                      : data.status == 'not_configured'
                      ? 'Not connected'
                      : 'Status unavailable',
                  style: TextStyle(
                    color: data.status == 'ok'
                        ? context.colors.success
                        : context.colors.textSecondary,
                  ),
                ),
                for (final credential in data.credentials)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      adminServiceIcon(credential.name),
                      color: context.colors.highlight,
                    ),
                    title: Text(credential.name),
                    subtitle: Text(switch (credential.status) {
                      'recorded' =>
                        'Last rotated ${DateFormat.yMMMd().add_jm().format(credential.lastRotatedAt!.toLocal())}',
                      'never_recorded' => 'No successful rotation recorded',
                      _ => 'Rotation status unavailable',
                    }),
                    trailing: Icon(
                      credential.status == 'recorded'
                          ? Icons.check_circle_rounded
                          : Icons.help_outline_rounded,
                      color: credential.status == 'recorded'
                          ? context.colors.success
                          : context.colors.textMuted,
                      size: 20,
                    ),
                  ),
                Text(
                  'Checked ${DateFormat.yMMMd().add_jm().format(data.checkedAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AdminRotationAction(),
        ],
      ),
    );
  }
}
