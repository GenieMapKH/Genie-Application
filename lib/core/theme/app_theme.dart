import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';

/// The two themes of the app, built from [AppColors]. Everything Material
/// draws on its own (dialogs, sheets, snack bars, text fields) is set up here
/// so screens only have to pick colours for what they draw themselves.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);

  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.light.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          error: colors.danger,
          outline: colors.border,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      // Inter has no Khmer letters; the device's own Khmer font fills in.
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.accent),
      textSelectionTheme: TextSelectionThemeData(cursorColor: colors.primary),
      extensions: [colors],
    );
  }
}
