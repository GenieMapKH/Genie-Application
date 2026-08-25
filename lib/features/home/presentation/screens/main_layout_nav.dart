// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'main_layout.dart';

extension MainLayoutNav on MainLayoutState {
  Widget buildBottomNavigationBar() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    Widget navContent = Container(
      height: 98.0,
      decoration: BoxDecoration(
        color: isIOS ? Colors.white.withValues(alpha: 0.85) : Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildNavItem(
              index: 0,
              iconPath: 'assets/icons/explore.svg',
              label: 'Explore',
            ),
            buildNavItem(
              index: 1,
              iconPath: 'assets/icons/saved.svg',
              label: 'Saved',
            ),
            buildNavItem(
              index: 2,
              iconPath: 'assets/icons/chat.svg',
              label: 'Chat',
            ),
            buildNavItem(
              index: 3,
              iconPath: 'assets/icons/property.svg',
              label: 'My Properties',
            ),
            buildNavItem(
              index: 4,
              iconPath: 'assets/icons/user.svg',
              label: 'User',
            ),
          ],
        ),
      ),
    );

    if (isIOS) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: navContent,
        ),
      );
    }

    return navContent;
  }

  Widget buildNavItem({
    required int index,
    required String iconPath,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? const Color(0xFF3E49C7)
        : const Color(0xFF6B7280);

    return TactileButton(
      onPressed: () async {
        if (index == 3 || index == 4) {
          final token = await AuthStorage.getAccessToken();
          if (token == null) {
            if (mounted) {
              showLoginRequiredDialog(context);
            }
            return;
          }
        }
        setState(() {
          previousIndex = currentIndex;
          currentIndex = index;
        });
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Text(
            'Account Required',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Please log in or sign up to access this feature.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FEF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              },
              child: Text(
                'Login / Sign Up',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
