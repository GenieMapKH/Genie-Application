import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:genie/shared/widgets/tactile_button.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'package:genie/features/home/presentation/providers/main_nav_provider.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';

class MainBottomNav extends ConsumerWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavProvider).currentIndex;
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
            _buildNavItem(
              context,
              ref,
              0,
              'assets/icons/explore.svg',
              'Explore',
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              1,
              'assets/icons/saved.svg',
              'Saved',
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              2,
              'assets/icons/chat.svg',
              'Chat',
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              3,
              'assets/icons/property.svg',
              'My Properties',
              currentIndex,
            ),
            _buildNavItem(
              context,
              ref,
              4,
              'assets/icons/user.svg',
              'User',
              currentIndex,
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

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    String iconPath,
    String label,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? const Color(0xFF3E49C7)
        : const Color(0xFF6B7280);

    final unreadCount = index == 2 ? ref.watch(unreadCountProvider) : 0;

    Widget iconWidget = SvgPicture.asset(
      iconPath,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    if (index == 2 && unreadCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return TactileButton(
      onPressed: () async {
        if (index == 1 || index == 2 || index == 3 || index == 4) {
          final token = await AuthStorage.getAccessToken();
          if (token == null) {
            if (context.mounted) {
              _showLoginRequiredDialog(context);
            }
            return;
          }
        }
        ref.read(mainNavProvider.notifier).setIndex(index);
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
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

  void _showLoginRequiredDialog(BuildContext context) {
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
