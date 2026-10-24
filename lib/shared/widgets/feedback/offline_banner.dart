import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genie/core/network/network_status.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// Puts a bar under [child] while the server cannot be reached, saying the
/// app shows what it kept. Waits [_showAfter] first: a single dropped request
/// that a retry repairs should not make it flicker.
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  static const _showAfter = Duration(seconds: 2);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final _online = NetworkStatus.instance.online;
  Timer? _pending;
  bool _shown = false;

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
        if (mounted && !_online.value) setState(() => _shown = true);
      });
    }
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
