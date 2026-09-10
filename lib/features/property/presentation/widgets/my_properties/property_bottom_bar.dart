import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class PropertyBottomBar extends StatelessWidget {
  const PropertyBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/icons/home.svg', 'Home', false),
          _buildNavItem('assets/icons/chat.svg', 'Messages', false),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(
            'assets/icons/heart.svg',
            'Favorites',
            false,
            hasBadge: true,
          ),
          _buildNavItem('assets/icons/user.svg', 'Profile', true),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String iconPath,
    String label,
    bool isActive, {
    bool hasBadge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(
                isActive ? const Color(0xFF5B5FEF) : const Color(0xFF9CA3AF),
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
            if (hasBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF5B5FEF) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
