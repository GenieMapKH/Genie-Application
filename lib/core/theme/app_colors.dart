import 'package:flutter/material.dart';

/// Every colour the app paints with, by what it is for. Widgets read these
/// through `context.colors` instead of writing hex values, so the light and
/// dark themes stay in this one file.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Behind a whole screen.
  final Color background;

  /// Cards, sheets, dialogs and bars that sit on the [background].
  final Color surface;

  /// A quieter fill inside a surface: text fields, chips, placeholders.
  final Color surfaceMuted;

  /// Outlines of cards and fields.
  final Color border;

  /// Hairlines between rows.
  final Color divider;

  /// Titles and anything the eye should land on first.
  final Color textPrimary;

  /// Body text next to a title.
  final Color textSecondary;

  /// Labels, values and captions.
  final Color textMuted;

  /// Placeholders and disabled text.
  final Color textHint;

  /// Chevrons and other decoration that should stay in the background.
  final Color iconSubtle;

  /// The brand colour: main buttons and focused fields.
  final Color primary;

  /// The brighter brand tone used for links, toggles and highlights.
  final Color accent;

  /// The deeper brand tone that marks the selected tab.
  final Color primaryStrong;

  /// A tint of the brand colour behind an icon or a selected row.
  final Color primarySoft;

  /// Text and icons on top of [primary] or [accent].
  final Color onPrimary;

  /// Destructive actions and errors.
  final Color danger;

  /// Background of an error or warning box.
  final Color dangerSoft;

  /// Outline of an error or warning box.
  final Color dangerBorder;

  /// Text inside an error or warning box.
  final Color onDangerSoft;

  /// Confirmation of something that went well.
  final Color success;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textHint,
    required this.iconSubtle,
    required this.primary,
    required this.accent,
    required this.primaryStrong,
    required this.primarySoft,
    required this.onPrimary,
    required this.danger,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.onDangerSoft,
    required this.success,
  });

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF9FAFB),
    border: Color(0xFFE5E7EB),
    divider: Color(0xFFF3F4F6),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF6B7280),
    textHint: Color(0xFF9CA3AF),
    iconSubtle: Color(0xFFD1D5DB),
    primary: Color(0xFF4F5BD5),
    accent: Color(0xFF5B5FEF),
    primaryStrong: Color(0xFF3E49C7),
    primarySoft: Color(0xFFEEF2FF),
    onPrimary: Color(0xFFFFFFFF),
    danger: Color(0xFFEF4444),
    dangerSoft: Color(0xFFFEF2F2),
    dangerBorder: Color(0xFFFECACA),
    onDangerSoft: Color(0xFFB91C1C),
    success: Color(0xFF10B981),
  );

  /// Brand tones are lighter here than in [light]: the light theme's blues
  /// are too dark to read as text on a dark surface.
  static const dark = AppColors(
    background: Color(0xFF0F1115),
    surface: Color(0xFF181B20),
    surfaceMuted: Color(0xFF20242B),
    border: Color(0xFF2C313A),
    divider: Color(0xFF23272E),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFC5CAD3),
    textMuted: Color(0xFF9AA1AC),
    textHint: Color(0xFF6B7280),
    iconSubtle: Color(0xFF4B5563),
    primary: Color(0xFF6570E3),
    accent: Color(0xFF8286F5),
    primaryStrong: Color(0xFF99A1F7),
    primarySoft: Color(0xFF23274A),
    onPrimary: Color(0xFFFFFFFF),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF341A1C),
    dangerBorder: Color(0xFF7F1D1D),
    onDangerSoft: Color(0xFFFCA5A5),
    success: Color(0xFF34D399),
  );

  @override
  AppColors copyWith() => this;

  /// Called while the theme animates between light and dark.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color mix(Color from, Color to) => Color.lerp(from, to, t)!;
    return AppColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      textHint: mix(textHint, other.textHint),
      iconSubtle: mix(iconSubtle, other.iconSubtle),
      primary: mix(primary, other.primary),
      accent: mix(accent, other.accent),
      primaryStrong: mix(primaryStrong, other.primaryStrong),
      primarySoft: mix(primarySoft, other.primarySoft),
      onPrimary: mix(onPrimary, other.onPrimary),
      danger: mix(danger, other.danger),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      dangerBorder: mix(dangerBorder, other.dangerBorder),
      onDangerSoft: mix(onDangerSoft, other.onDangerSoft),
      success: mix(success, other.success),
    );
  }
}

extension AppColorsContext on BuildContext {
  /// The palette of the theme in use. Falls back to the light one where no
  /// app theme is installed (a bare `MaterialApp` in a widget test).
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
