import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tilomnov/app/session/sign_out.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/security/data/models/device_session.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';
import 'package:tilomnov/features/security/presentation/widgets/device_session_tile.dart';
import 'package:tilomnov/features/security/presentation/widgets/info_note.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// The devices signed in to the account, with a way to sign out one of them
/// or all of them.
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sessions = ref.watch(deviceSessionsProvider);

    return AppPageScaffold(
      title: l10n.securityDevices,
      child: RefreshIndicator(
        color: context.colors.accent,
        onRefresh: () => ref.refresh(deviceSessionsProvider.future),
        child: sessions.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _LoadError(onRetry: () => ref.invalidate(deviceSessionsProvider)),
          data: (devices) => _DeviceList(devices: devices),
        ),
      ),
    );
  }
}

class _DeviceList extends ConsumerStatefulWidget {
  final DeviceList devices;

  const _DeviceList({required this.devices});

  @override
  ConsumerState<_DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends ConsumerState<_DeviceList> {
  /// True while a sign-out is on its way, so nothing is tapped twice.
  bool _isBusy = false;

  Future<void> _signOut(DeviceSession session) async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.devicesSignOutConfirmTitle,
      message: l10n.devicesSignOutConfirmMessage(
        session.deviceName ?? l10n.devicesUnknownDevice,
      ),
      action: l10n.devicesSignOut,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isBusy = true);
    final signedOut = await ref
        .read(deviceSessionsProvider.notifier)
        .signOut(session);
    if (!mounted) return;
    setState(() => _isBusy = false);

    if (signedOut) {
      AppPopup.showSuccess(context, l10n.devicesSignedOut);
    } else {
      AppPopup.showError(context, l10n.devicesSignOutFailed);
    }
  }

  Future<void> _signOutAll() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.devicesSignOutAllConfirmTitle,
      message: l10n.devicesSignOutAllConfirmMessage,
      action: l10n.devicesSignOutAll,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isBusy = true);
    final signedOut = await ref
        .read(deviceSessionsProvider.notifier)
        .signOutAll();
    if (!mounted) return;
    if (!signedOut) {
      setState(() => _isBusy = false);
      AppPopup.showError(context, l10n.devicesSignOutFailed);
      return;
    }

    // This device was signed out too: forget the session and start over.
    await ref.read(signOutProvider)();
    if (mounted) context.go('/');
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.colors.danger,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final caption = TextStyle(
      fontSize: 13,
      height: 1.45,
      color: colors.textMuted,
    );

    final devices = widget.devices;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text(l10n.devicesIntro, style: caption.copyWith(fontSize: 14)),
        const SizedBox(height: 20),
        for (final session in devices.sessions) ...[
          DeviceSessionTile(
            session: session,
            canSignOut: devices.canSignOutOthers,
            onSignOut: _isBusy ? null : () => _signOut(session),
          ),
          const SizedBox(height: 12),
        ],
        // Only this device is listed (or none, on a session older than the list).
        if (devices.others.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.devicesEmpty, style: caption),
          ),
        const SizedBox(height: 12),
        if (devices.canSignOutOthers) ...[
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _signOutAll,
            icon: const Icon(Icons.logout, size: 18),
            label: Text(l10n.devicesSignOutAll),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.danger,
              side: BorderSide(color: colors.dangerBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.devicesImmediateNote, style: caption),
        ] else if (devices.others.isNotEmpty)
          InfoNote(_tooNewNote(context, devices.canSignOutOthersFrom)),
      ],
    );
  }

  /// Why this device cannot sign the others out yet, and from when it can.
  String _tooNewNote(BuildContext context, DateTime? allowedFrom) {
    final l10n = context.l10n;
    if (allowedFrom == null) return l10n.devicesTooNew;

    final when = DateFormat.MMMd(
      Localizations.localeOf(context).languageCode,
    ).add_jm().format(allowedFrom.toLocal());
    return l10n.devicesTooNewUntil(when);
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.textHint),
              const SizedBox(height: 16),
              Text(
                l10n.devicesLoadFailed,
                style: TextStyle(fontSize: 16, color: colors.textMuted),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      ],
    );
  }
}
