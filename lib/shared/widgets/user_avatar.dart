import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/theme/app_colors.dart';

/// Round picture of a person, or their initial when they have none.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasPicture = url != null && url.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: context.colors.border,
      backgroundImage: hasPicture ? NetworkImage(url) : null,
      child: hasPicture
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
                color: context.colors.textMuted,
              ),
            ),
    );
  }
}
