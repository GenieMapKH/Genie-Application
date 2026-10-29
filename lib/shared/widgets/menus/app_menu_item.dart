import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';

/// One row of a popup menu: icon and label in the app's style. [danger]
/// colours it red, for actions such as delete, report or block.
///
/// The menu around it (card, corners, border) comes from the theme's
/// `popupMenuTheme`.
PopupMenuItem<T> appMenuItem<T>(
  BuildContext context, {
  T? value,
  required IconData icon,
  required String label,
  bool danger = false,
  VoidCallback? onTap,
}) {
  final colors = context.colors;
  final tint = danger ? colors.danger : colors.textPrimary;
  return PopupMenuItem<T>(
    value: value,
    onTap: onTap,
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: danger ? colors.danger : colors.textSecondary,
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: tint,
            ),
          ),
        ),
      ],
    ),
  );
}
