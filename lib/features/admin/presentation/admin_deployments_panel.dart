import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import '../data/admin_operations.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'admin_service_card.dart';
import 'admin_dashboard_provider.dart';
import 'admin_moderation_dialog.dart';
import 'admin_operations_provider.dart';

class AdminDeploymentsPanel extends ConsumerStatefulWidget {
  const AdminDeploymentsPanel({super.key});
  @override
  ConsumerState<AdminDeploymentsPanel> createState() =>
      _AdminDeploymentsPanelState();
}

class _AdminDeploymentsPanelState extends ConsumerState<AdminDeploymentsPanel> {
  bool _busy = false;
  Future<void> _rollback(AdminServiceDeployments service) async {
    final previous = service.previous!;
    final reason = await confirmModeration(
      context,
      title: 'Roll back ${service.name}',
      message:
          'Restore ${service.name} to ${previous.commit ?? previous.id} from ${DateFormat.yMMMd().add_jm().format(previous.createdAt.toLocal())}? Railway restores the deployment and its custom variables. Database migrations, stored data and mobile app releases are unchanged. Other services must be recovered separately.',
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminOperationsRepositoryProvider)
          .rollback(service, reason);
      if (!mounted) return;
      ref.invalidate(adminDeploymentsProvider);
      ref.invalidate(adminSystemHealthProvider);
      AppPopup.showSuccess(
        context,
        'Rollback requested. Refresh deployments and service status to verify recovery.',
      );
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          error: error,
          fallback:
              'Rollback could not be confirmed. Refresh deployments; changed credentials or an active rotation can block recovery.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(AdminDeployment deployment) =>
      '${deployment.commit ?? deployment.id} Â· ${deployment.status}\n${DateFormat.yMMMd().add_jm().format(deployment.createdAt.toLocal())}';

  @override
  Widget build(BuildContext context) {
    final deployments = ref.watch(adminDeploymentsProvider);
    final colors = context.colors;
    return AdminServiceCard(
      icon: LucideIcons.cloudCheck,
      title: 'Railway',
      onRefresh: () => ref.invalidate(adminDeploymentsProvider),
      refreshing: deployments.isLoading && deployments.hasValue,
      refreshFailed: deployments.hasError && deployments.hasValue,
      child: deployments.when(
        skipLoadingOnReload: true,
        skipError: true,
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Deployment history unavailable'),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              data.status == 'ok' ? 'Connected ? production' : 'Not connected',
              style: TextStyle(
                color: data.status == 'ok' ? colors.success : colors.textMuted,
              ),
            ),
            for (final service in data.services)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          adminServiceIcon(service.name),
                          color: colors.highlight,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(
                          service.latest?.status == 'SUCCESS'
                              ? LucideIcons.circleCheck
                              : LucideIcons.info,
                          color: service.latest?.status == 'SUCCESS'
                              ? colors.success
                              : colors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      service.latest == null
                          ? 'No deployment found'
                          : 'Latest: ${_describe(service.latest!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.previous == null
                          ? 'No rollback available'
                          : 'Previous: ${_describe(service.previous!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed:
                            _busy ||
                                deployments.isLoading ||
                                deployments.hasError ||
                                service.previous == null ||
                                service.latest == null ||
                                !const [
                                  'SUCCESS',
                                  'FAILED',
                                  'CRASHED',
                                  'REMOVED',
                                  'SKIPPED',
                                ].contains(service.latest!.status)
                            ? null
                            : () => _rollback(service),
                        icon: const Icon(LucideIcons.undo2, size: 18),
                        label: Text('Roll back ${service.name}'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
