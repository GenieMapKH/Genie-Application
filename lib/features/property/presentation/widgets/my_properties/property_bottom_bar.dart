import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/media/tinted_svg.dart';

class PropertyBottomBar extends StatelessWidget {
  const PropertyBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
          _buildNavItem(
            context,
            'assets/icons/home.svg',
            context.l10n.navExplore,
            false,
          ),
          _buildNavItem(
            context,
            'assets/icons/chat.svg',
            context.l10n.navChat,
            false,
          ),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(
            context,
            'assets/icons/heart.svg',
            context.l10n.navSaved,
            false,
            hasBadge: true,
          ),
          _buildNavItem(
            context,
            'assets/icons/user.svg',
            context.l10n.navUser,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
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
            TintedSvg(
              iconPath,
              color: isActive ? context.colors.accent : context.colors.textHint,
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
            color: isActive ? context.colors.accent : context.colors.textHint,
          ),
        ),
      ],
    );
  }
}
