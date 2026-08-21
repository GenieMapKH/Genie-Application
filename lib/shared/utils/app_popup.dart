import 'package:flutter/material.dart';

class AppPopup {
  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF10B981), // Emerald Green
      backgroundColor: const Color(0xFF064E3B), // Very dark emerald
      borderColor: const Color(0xFF059669).withValues(alpha: 0.3),
    );
  }

  static void showError(BuildContext context, String message) {
    _showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.error_rounded,
      iconColor: const Color(0xFFEF4444), // Rose Red
      backgroundColor: const Color(0xFF4C0519), // Very dark rose
      borderColor: const Color(0xFFE11D48).withValues(alpha: 0.3),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showCustomSnackBar(
      context: context,
      message: message,
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF3B82F6), // Blue
      backgroundColor: const Color(0xFF1E3A8A), // Very dark blue
      borderColor: const Color(0xFF2563EB).withValues(alpha: 0.3),
    );
  }

  static void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.none,
      margin: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
