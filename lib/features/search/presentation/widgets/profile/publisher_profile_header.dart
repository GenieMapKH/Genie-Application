import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/search/data/models/publisher_summary.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/cover_banner_header.dart';
import 'package:genie/shared/widgets/user_avatar.dart';

/// Top of a publisher's profile: a cover with their picture and the follow
/// button, their name and handle, how many listings they have and since
/// when they are a member, then the chat and "view on map" buttons.
class PublisherProfileHeader extends StatelessWidget {
  final PublisherSummary person;

  /// Null hides the button: nothing to show on the map.
  final VoidCallback? onViewOnMap;

  /// The follow button. Following is not built yet: the page passes a
  /// handler that does nothing.
  final VoidCallback onFollow;

  /// Null hides the button: your own profile.
  final VoidCallback? onChat;

  const PublisherProfileHeader({
    super.key,
    required this.person,
    this.onViewOnMap,
    required this.onFollow,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CoverBannerHeader(
          avatarRadius: 44,
          avatar: UserAvatar(
            name: person.displayName,
            avatarUrl: person.avatarUrl,
            radius: 44,
          ),
          trailing: _FollowButton(onPressed: onFollow),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _PublisherIdentity(person: person),
        ),
        if (onChat != null || onViewOnMap != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _PublisherActions(onChat: onChat, onViewOnMap: onViewOnMap),
          ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FollowButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Inverted from the page (light on dark, dark on light) so it stands
    // out from both the cover and the blue "Chat".
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(
        context.l10n.profileFollow,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.background,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Name, handle, and a line each for their listings and membership.
class _PublisherIdentity extends StatelessWidget {
  final PublisherSummary person;

  const _PublisherIdentity({required this.person});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final handle = person.username;
    final since = person.memberSince;
    final factStyle = GoogleFonts.inter(
      fontSize: 14,
      color: colors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          person.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        if (handle != null && handle != person.displayName) ...[
          const SizedBox(height: 2),
          Text(
            '@$handle',
            style: GoogleFonts.inter(fontSize: 14, color: colors.textMuted),
          ),
        ],
        const SizedBox(height: 12),
        _Fact(
          icon: Icons.holiday_village_outlined,
          child: Row(
            children: [
              Text(
                NumberFormat.decimalPattern().format(person.listingCount),
                style: factStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.profileListingsStat,
                  overflow: TextOverflow.ellipsis,
                  style: factStyle,
                ),
              ),
            ],
          ),
        ),
        if (since != null) ...[
          const SizedBox(height: 8),
          _Fact(
            icon: Icons.calendar_today_outlined,
            child: Text(
              l10n.profileMemberSince(
                DateFormat.yMMMM(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(since.toLocal()),
              ),
              overflow: TextOverflow.ellipsis,
              style: factStyle,
            ),
          ),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _Fact({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.colors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

/// "Chat" as the main action, "View on map" beside it; whichever is
/// present fills the row on its own.
class _PublisherActions extends StatelessWidget {
  final VoidCallback? onChat;
  final VoidCallback? onViewOnMap;

  const _PublisherActions({this.onChat, this.onViewOnMap});

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(22),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final onChat = this.onChat;
    final onViewOnMap = this.onViewOnMap;

    return Row(
      children: [
        if (onChat != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: _ButtonLabel(l10n.profileChat),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size(0, 44),
                shape: _shape,
              ),
            ),
          ),
        if (onChat != null && onViewOnMap != null) const SizedBox(width: 12),
        if (onViewOnMap != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onViewOnMap,
              icon: Icon(Icons.map_outlined, size: 18, color: colors.accent),
              label: _ButtonLabel(l10n.profileViewOnMap, color: colors.accent),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                side: BorderSide(color: colors.border),
                shape: _shape,
              ),
            ),
          ),
      ],
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const _ButtonLabel(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: color),
    );
  }
}
