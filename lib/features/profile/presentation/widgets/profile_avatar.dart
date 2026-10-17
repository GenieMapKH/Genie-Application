import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/widgets/avatar_options_sheet.dart';
import 'package:genie/l10n/l10n.dart';

/// Top of the account screen: the picture, the name people see and the handle.
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = profile.displayName ?? context.l10n.accountDefaultName;
    final username = profile.username;

    return Column(
      children: [
        ProfileAvatar(
          avatarUrl: profile.avatarUrl,
          name: name,
          onEditPressed: () => showAvatarOptions(context, profile),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        if (username != null) ...[
          const SizedBox(height: 2),
          Text(
            '@$username',
            style: TextStyle(fontSize: 14, color: colors.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Round profile picture (or the first letter of [name]) with the camera
/// button, which calls [onEditPressed].
class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final VoidCallback onEditPressed;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = this.avatarUrl;

    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: colors.border,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  name.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: colors.textHint,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onEditPressed,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: colors.background, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 18, color: colors.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
