import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';

/// Puts a bar under [child] while the server cannot be reached, saying the
/// app shows what it kept. Waits [_showAfter] first: a single dropped request
/// that a retry repairs should not make it flicker.
///
/// The first time it shows in an outage it also opens [_OfflineDialog] over
/// the current screen (on [navigatorKey]'s navigator); the bar stays after
/// the dialog is dismissed.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const OfflineBanner({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  static const _showAfter = Duration(seconds: 2);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final _online = NetworkStatus.instance.online;
  Timer? _pending;
  bool _shown = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _online.addListener(_follow);
    _follow();
  }

  @override
  void dispose() {
    _online.removeListener(_follow);
    _pending?.cancel();
    super.dispose();
  }

  void _follow() {
    if (_online.value) {
      _pending?.cancel();
      _pending = null;
      if (_shown) setState(() => _shown = false);
    } else {
      _pending ??= Timer(OfflineBanner._showAfter, () {
        _pending = null;
        if (!mounted || _online.value) return;
        setState(() => _shown = true);
        _openDialog();
      });
    }
  }

  Future<void> _openDialog() async {
    final context = widget.navigatorKey.currentContext;
    if (_dialogOpen || context == null) return;
    _dialogOpen = true;
    await AppDialog.show<void>(context, builder: (_) => const _OfflineDialog());
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // The bar covers the bottom inset itself while it shows.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: _shown,
            child: widget.child,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _shown ? const _Bar() : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// "No internet connection", with Retry. Closes itself once the server can
/// be reached again.
class _OfflineDialog extends StatefulWidget {
  const _OfflineDialog();

  @override
  State<_OfflineDialog> createState() => _OfflineDialogState();
}

class _OfflineDialogState extends State<_OfflineDialog> {
  final _online = NetworkStatus.instance.online;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _online.addListener(_closeWhenOnline);
  }

  @override
  void dispose() {
    _online.removeListener(_closeWhenOnline);
    super.dispose();
  }

  void _closeWhenOnline() {
    if (!_online.value || !mounted) return;
    // This route only, even if another dialog has opened over it.
    final route = ModalRoute.of(context);
    if (route != null) Navigator.of(context).removeRoute(route);
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    await NetworkStatus.instance.checkNow();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      icon: Icons.wifi_off_rounded,
      title: l10n.offlineDialogTitle,
      message: l10n.offlineDialogMessage,
      primaryLabel: l10n.commonRetry,
      onPrimary: _retry,
      primaryBusy: _checking,
      secondaryLabel: l10n.offlineKeepBrowsing,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.textPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 18, color: colors.surface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.commonOffline,
                  style: TextStyle(color: colors.surface, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
