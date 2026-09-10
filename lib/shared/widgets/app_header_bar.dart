import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Standardized, consistent top app header bar used across screens (Account, Saved Properties, My Properties, etc.).
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final bool showBackButton;
  final Color backgroundColor;

  const AppHeaderBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.trailing,
    this.showBackButton = true,
    this.backgroundColor = Colors.white,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button
          if (showBackButton)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF111827),
                    size: 24,
                  ),
                ),
              ),
            ),

          // Centered Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),

          // Trailing Widget (e.g. Saved count badge or Action button)
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
