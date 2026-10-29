import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/search/data/search_failure.dart';
import 'package:tilomnov/l10n/l10n.dart';

/// An icon, a title, a sentence and maybe a button: what search shows when it
/// has no list to show (nothing typed, nothing found, something failed).
class SearchMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SearchMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  /// The explanation of [reason], with a retry button.
  factory SearchMessageView.failure(
    BuildContext context,
    SearchFailureReason reason, {
    VoidCallback? onRetry,
  }) {
    final l10n = context.l10n;
    final (icon, message) = switch (reason) {
      SearchFailureReason.offline => (
        Icons.wifi_off_rounded,
        l10n.searchFailureOffline,
      ),
      SearchFailureReason.tooManyRequests => (
        Icons.hourglass_empty_rounded,
        l10n.searchFailureTooManyRequests,
      ),
      SearchFailureReason.unavailable => (
        Icons.cloud_off_rounded,
        l10n.searchFailureUnavailable,
      ),
      SearchFailureReason.notFound => (
        Icons.wrong_location_outlined,
        l10n.searchFailureNotFound,
      ),
      SearchFailureReason.unknown => (
        Icons.error_outline_rounded,
        l10n.searchFailureUnknown,
      ),
    };
    return SearchMessageView(
      icon: icon,
      title: message,
      actionLabel: onRetry == null ? null : l10n.commonRetry,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: colors.textHint),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.45,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
