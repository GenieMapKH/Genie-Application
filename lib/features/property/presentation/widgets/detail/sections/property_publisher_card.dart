import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/follow/presentation/follow_actions.dart';
import 'package:tilomnov/features/follow/presentation/view_models/follow_providers.dart';
import 'package:tilomnov/features/follow/presentation/widgets/follow_button.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_publisher_opener.dart';
import 'package:tilomnov/features/property/utils/property_format.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/owner_display_name.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';

/// "Listed by": who posted the listing, with "View Profile" and "Follow".
/// Nothing for a listing whose owner is unknown.
class PropertyPublisherCard extends ConsumerWidget {
  final PropertyModel property;

  /// The viewer posted it: no following yourself.
  final bool isOwner;

  const PropertyPublisherCard({
    super.key,
    required this.property,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerId = property.ownerId;
    if (ownerId == null) return const SizedBox.shrink();

    final colors = context.colors;
    final name = ownerDisplayName(context.l10n, property.ownerName);
    final openProfile = ref.watch(propertyPublisherOpenerProvider);
    // Counts and the follow state need a signed-in viewer; a guest sees a
    // "Follow" that asks them to sign in.
    final signedIn = ref.watch(isSignedInProvider);
    final followState = signedIn && !isOwner
        ? ref.watch(followSummaryProvider(ownerId))
        : null;
    final follow = followState?.valueOrNull;
    // Only while it loads: when it could not be read, a "Follow" that asks
    // again.
    final followPending =
        followState != null && followState.isLoading && follow == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.propertyPublisherTitle,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  UserAvatar(
                    name: name,
                    avatarUrl: property.ownerAvatarUrl,
                    radius: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PublisherIdentity(
                      name: name,
                      property: property,
                      followerCount: follow?.followerCount,
                    ),
                  ),
                ],
              ),
              if (openProfile != null || !isOwner) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (openProfile != null)
                      Expanded(
                        child: _ViewProfileButton(
                          onPressed: () => openProfile(
                            context,
                            PropertyPublisher(
                              userId: ownerId,
                              name: property.ownerName,
                              avatarUrl: property.ownerAvatarUrl,
                            ),
                          ),
                        ),
                      ),
                    if (openProfile != null && !isOwner)
                      const SizedBox(width: 10),
                    if (!isOwner)
                      Expanded(
                        child: PublisherFollowButton(
                          following: followPending
                              ? null
                              : follow?.isFollowing ?? false,
                          onPressed: () => toggleFollow(context, ref, ownerId),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Name, then "@handle", then since when they are a member and how many
/// follow them, each when known.
class _PublisherIdentity extends StatelessWidget {
  final String name;
  final PropertyModel property;
  final int? followerCount;

  const _PublisherIdentity({
    required this.name,
    required this.property,
    this.followerCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final username = property.ownerUsername?.trim();
    final since = property.ownerMemberSince;
    final secondary = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colors.textMuted,
    );
    final facts = [
      if (since != null)
        l10n.profileMemberSince(
          DateFormat.yMMMM(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(since.toLocal()),
        ),
      if (followerCount != null)
        '${PropertyFormat.count(followerCount!)} ${l10n.profileFollowersStat}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        if (username != null && username.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: secondary,
          ),
        ],
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            facts.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: secondary,
          ),
        ],
      ],
    );
  }
}

class _ViewProfileButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ViewProfileButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.border),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        context.l10n.propertyPublisherViewProfile,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
