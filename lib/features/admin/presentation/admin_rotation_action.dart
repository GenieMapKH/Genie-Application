import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'admin_dashboard_provider.dart';
import 'admin_operations_provider.dart';

class AdminRotationAction extends ConsumerStatefulWidget {
  const AdminRotationAction({super.key});
  @override
  ConsumerState<AdminRotationAction> createState() =>
      _AdminRotationActionState();
}

class _AdminRotationActionState extends ConsumerState<AdminRotationAction> {
  bool _busy = false;
  Future<void> _rotate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force rotate all'),
        content: const Text(
          'Rotate the six database credentials, internal service secret and JWT encryption key. Existing sessions remain valid. The job waits for each service to receive its credentials and stops if a handover fails. External provider keys are managed separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Force rotate all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminOperationsRepositoryProvider).forceRotation();
      if (!mounted) return;
      ref.invalidate(adminRotationJobProvider);
      AppPopup.showSuccess(
        context,
        'Rotation requested. Refresh workflow status to follow progress.',
      );
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          error: error,
          fallback:
              'Rotation could not be confirmed. Refresh workflow status before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(adminRotationJobProvider);
    return workflow.when(
      skipLoadingOnReload: true,
      skipError: true,
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(adminRotationJobProvider),
        child: const Text('Retry rotation workflow status'),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (workflow.hasError)
            const Text('Workflow refresh failed. Showing saved status.'),
          if (data.status == 'not_configured')
            const Text('Force rotation is not connected.'),
          if (data.runs.isNotEmpty)
            Text(
              'Latest workflow: ${data.runs.first.conclusion ?? data.runs.first.status} Â· ${DateFormat.yMMMd().add_jm().format(data.runs.first.createdAt.toLocal())}',
            ),
          if (data.busy)
            const Text(
              'Rotation is queued or running. Refresh to check progress.',
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed:
                    _busy ||
                        workflow.isLoading ||
                        workflow.hasError ||
                        data.busy ||
                        data.status != 'ok'
                    ? null
                    : _rotate,
                icon: const Icon(LucideIcons.refreshCw),
                label: Text(
                  _busy ? 'Requesting rotation…' : 'Force rotate all',
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.refreshCw),
                onPressed: () {
                  ref.invalidate(adminRotationJobProvider);
                  ref.invalidate(adminRotationProvider);
                },
                label: const Text('Refresh workflow'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
