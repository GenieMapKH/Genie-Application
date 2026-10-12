import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Round picture of a chat participant, or their initial when they have none.
class ChatAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const ChatAvatar({
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
      backgroundColor: const Color(0xFFE5E7EB),
      backgroundImage: hasPicture ? NetworkImage(url) : null,
      child: hasPicture
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
    );
  }
}
