import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

/// "Follow", or "Following" with a check once followed. While whether you
/// follow them is still loading ([following] null), a quiet spinner that
/// does nothing when tapped: never a "Follow" that turns into "Following".
class PublisherFollowButton extends StatelessWidget {
  final bool? following;
  final VoidCallback onPressed;

  const PublisherFollowButton({
    super.key,
    required this.following,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final following = this.following;
    if (following == null) return const _PendingFollowButton();
    final colors = context.colors;

    // Inverted from the page (light on dark, dark on light) so it stands
    // out from both the cover and the blue "Chat". Once following, it turns
    // quiet: the page's colours, with a check.
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(following ? Icons.check_rounded : Icons.add_rounded, size: 20),
      label: Text(
        following ? context.l10n.profileFollowing : context.l10n.profileFollow,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: following ? colors.surface : colors.textPrimary,
        foregroundColor: following ? colors.textPrimary : colors.background,
        side: following ? BorderSide(color: colors.border) : null,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// The follow button's place, in the quiet "Following" colours, while the
/// answer loads.
class _PendingFollowButton extends StatelessWidget {
  const _PendingFollowButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 96,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
