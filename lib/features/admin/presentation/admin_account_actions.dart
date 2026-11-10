import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'admin_dashboard_provider.dart';
import 'admin_records_provider.dart';
import 'admin_moderation_provider.dart';
import 'admin_moderation_dialog.dart';

class AdminAccountActions extends ConsumerStatefulWidget {
  final String userId;
  final String label;
  final VoidCallback? onChanged;
  final bool enabled;
  const AdminAccountActions({
    super.key,
    required this.userId,
    this.label = 'Account actions',
    this.onChanged,
    this.enabled = true,
  });
  @override
  ConsumerState<AdminAccountActions> createState() =>
      _AdminAccountActionsState();
}

class _AdminAccountActionsState extends ConsumerState<AdminAccountActions> {
  bool _busy = false;
  Future<void> _act(String action) async {
    final delete = action == 'delete';
    final reason = await confirmModeration(
      context,
      title: delete ? 'Delete account' : 'Ban account',
      message: delete
          ? 'Permanently delete this account and its listings, photos and chats. Financial records remain without account details. This cannot be undone.'
          : 'Block this account from signing in, end its sessions and hide all its posts. Signing in cannot lift this ban.',
      permanent: delete,
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final repository = ref.read(adminModerationRepositoryProvider);
      if (delete) {
        await repository.deleteUser(widget.userId, reason);
      } else {
        await repository.banUser(widget.userId, reason);
      }
      if (!mounted) return;
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminRecordsProvider);
      ref.invalidate(adminReportsProvider);
      AppPopup.showSuccess(context, 'Moderation action completed');
      widget.onChanged?.call();
    } catch (error) {
      if (mounted) {
        showFailure(
          context,
          error: error,
          fallback: 'Could not complete the account action. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    enabled: widget.enabled && !_busy,
    tooltip: widget.label,
    onSelected: _act,
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: 'ban',
        child: ListTile(
          leading: Icon(Icons.block_rounded),
          title: Text('Ban account'),
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete_forever_outlined),
          title: Text('Delete account permanently'),
        ),
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.admin_panel_settings_outlined),
          const SizedBox(width: 6),
          Text(widget.label),
        ],
      ),
    ),
  );
}
