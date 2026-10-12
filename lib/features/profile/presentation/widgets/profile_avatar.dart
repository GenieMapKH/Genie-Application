import 'package:flutter/material.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:google_fonts/google_fonts.dart';

/// Round profile picture (or initial) with the camera button.
class ProfileAvatar extends StatelessWidget {
  final UserProfile profile;

  const ProfileAvatar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showOptions(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5FEF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: wire these options up (camera, gallery, Google sync).
            for (final option in const [
              (Icons.camera_alt_outlined, 'Take photo'),
              (Icons.photo_library_outlined, 'Choose from storage'),
              (Icons.sync, 'Sync from Google Account'),
            ])
              ListTile(
                leading: Icon(option.$1),
                title: Text(option.$2),
                onTap: () => Navigator.pop(sheetContext),
              ),
          ],
        ),
      ),
    );
  }
}
