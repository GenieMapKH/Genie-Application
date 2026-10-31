import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';

/// Tells the user about the connection with the app's top popups
/// ([AppPopup]), over [child] and without moving it ([NetworkStatus]):
///
/// * offline: a red "No internet connection", once per outage, with a
///   retry button that asks the server at once. Waits [_offlineAfter]
///   first, so a single dropped request that a retry repairs shows nothing.
/// * back online after an outage that was shown: a green "Back online".
/// * weak: "Slow connection", at most once every [_slowEvery], since a very
///   weak line tends to stay weak.
///
/// It sits above the Navigator, so the popups go on [navigatorKey]'s overlay.
class ConnectionPopups extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const ConnectionPopups({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  static const _offlineAfter = Duration(seconds: 2);
  static const _slowEvery = Duration(minutes: 5);

  @override
  State<ConnectionPopups> createState() => _ConnectionPopupsState();
}

class _ConnectionPopupsState extends State<ConnectionPopups> {
  final _connection = NetworkStatus.instance.connection;
  Timer? _offlinePending;
  bool _offlineShown = false;
  DateTime? _slowShownAt;
  VoidCallback? _hideCurrent;

  @override
  void initState() {
    super.initState();
    _connection.addListener(_follow);
    _follow();
  }

  @override
  void dispose() {
    _connection.removeListener(_follow);
    _offlinePending?.cancel();
    super.dispose();
  }

  void _follow() {
    switch (_connection.value) {
      case ConnectionQuality.offline:
        if (_offlineShown || _offlinePending != null) return;
        _offlinePending = Timer(ConnectionPopups._offlineAfter, () {
          _offlinePending = null;
          if (mounted && _connection.value == ConnectionQuality.offline) {
            _showOffline();
          }
        });
      case ConnectionQuality.weak:
        _cancelOffline();
        final last = _slowShownAt;
        if (last != null &&
            DateTime.now().difference(last) < ConnectionPopups._slowEvery) {
          return;
        }
        final l10n = context.l10n;
        if (_show(
          '${l10n.connectionWeak} · ${l10n.connectionWeakDetail}',
          AppPopupTone.info,
          Icons.network_wifi_1_bar_rounded,
        )) {
          _slowShownAt = DateTime.now();
        }
      case ConnectionQuality.good:
        _cancelOffline();
    }
  }

  void _showOffline() {
    _offlineShown = _show(
      context.l10n.connectionOffline,
      AppPopupTone.error,
      Icons.wifi_off_rounded,
      onRetry: _retryConnection,
    );
  }

  /// Retry: asks the server now. Back online, "Back online" follows and the
  /// screens read again; still offline, it says so again.
  Future<void> _retryConnection() async {
    await NetworkStatus.instance.checkNow();
    if (mounted && _connection.value == ConnectionQuality.offline) {
      _showOffline();
    }
  }

  /// The outage ended (or the line is only slow now): no offline popup is
  /// waiting, and one already shown gives way to "Back online".
  void _cancelOffline() {
    _offlinePending?.cancel();
    _offlinePending = null;
    if (!_offlineShown) return;
    _offlineShown = false;
    _show(
      context.l10n.connectionRestored,
      AppPopupTone.success,
      Icons.wifi_rounded,
    );
  }

  /// Replaces the popup this widget showed last. False when there is no
  /// overlay yet to show it on (the app is still starting).
  bool _show(
    String message,
    AppPopupTone tone,
    IconData icon, {
    VoidCallback? onRetry,
  }) {
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return false;
    _hideCurrent?.call();
    _hideCurrent = AppPopup.showOn(
      overlay,
      message,
      tone: tone,
      icon: icon,
      onRetry: onRetry,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
