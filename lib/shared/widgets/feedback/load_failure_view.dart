import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/network/load_failure.dart';
import 'package:tilomnov/core/network/network_status.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// What a screen shows when its content could not be loaded: why, in plain
/// words (no internet, a slow connection, the server), and Retry.
///
/// When the connection was the reason, it waits for it to come back and
/// then calls [onRetry] by itself.
class LoadFailureView extends StatefulWidget {
  /// What the repository threw.
  final Object? error;

  /// The screen's own sentence, for a failure that is not the connection's
  /// ("Could not load your chats.").
  final String message;

  final VoidCallback onRetry;

  const LoadFailureView({
    super.key,
    required this.error,
    required this.message,
    required this.onRetry,
  });

  @override
  State<LoadFailureView> createState() => _LoadFailureViewState();
}

class _LoadFailureViewState extends State<LoadFailureView> {
  final _connection = NetworkStatus.instance.connection;
  late ConnectionQuality _lastQuality;

  LoadFailure get _failure => LoadFailure.of(widget.error);

  @override
  void initState() {
    super.initState();
    _lastQuality = _connection.value;
    _connection.addListener(_retryWhenBetter);
  }

  @override
  void dispose() {
    _connection.removeListener(_retryWhenBetter);
    super.dispose();
  }

  void _retryWhenBetter() {
    final quality = _connection.value;
    final better = quality.index < _lastQuality.index;
    _lastQuality = quality;
    if (mounted) setState(() {});
    if (better && _failure.isConnection) widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure;
    final (icon, title, body) = switch (failure) {
      LoadFailure.offline => (
        Icons.wifi_off_rounded,
        l10n.loadFailureOfflineTitle,
        l10n.loadFailureOfflineBody,
      ),
      LoadFailure.slow => (
        Icons.network_check_rounded,
        l10n.loadFailureSlowTitle,
        l10n.loadFailureSlowBody,
      ),
      LoadFailure.server => (
        Icons.cloud_off_rounded,
        widget.message,
        l10n.loadFailureServerBody,
      ),
      LoadFailure.other => (Icons.error_outline_rounded, widget.message, null),
    };
    final waiting =
        failure == LoadFailure.offline &&
        _connection.value == ConnectionQuality.offline;

    return _FailureMessage(
      icon: icon,
      title: title,
      body: body,
      footer: waiting ? const _WaitingForConnection() : null,
      onRetry: widget.onRetry,
    );
  }
}

class _FailureMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? footer;
  final VoidCallback onRetry;

  const _FailureMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.footer,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = this.body;
    final footer = this.footer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: colors.textHint),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.45,
              ),
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 16), footer],
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              context.l10n.commonRetry,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small spinner and "Waiting for connection…": the screen will load by
/// itself, nothing is stuck.
class _WaitingForConnection extends StatelessWidget {
  const _WaitingForConnection();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.textHint,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          context.l10n.connectionWaiting,
          style: GoogleFonts.inter(fontSize: 13, color: colors.textHint),
        ),
      ],
    );
  }
}
