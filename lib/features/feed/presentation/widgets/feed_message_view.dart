import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/shared/widgets/feedback/empty_state_card.dart';

/// What the feed shows when the user follows no one with listings.
class FeedMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final String actionLabel;
  final VoidCallback onAction;

  const FeedMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return EmptyStateCard(
      icon: icon,
      title: title,
      hint: hint,
      action: FilledButton(
        onPressed: onAction,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          actionLabel,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
