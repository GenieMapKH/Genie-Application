import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the look and language the user picked, on this device.
/// Nothing is stored until they pick something, so by default the app
/// follows the phone.
class AppSettingsStorage {
  static const _themeModeKey = 'settings.theme_mode';
  static const _languageKey = 'settings.language';
  static const _showNotificationTextKey = 'settings.show_notification_text';
  static const _glassNavigationKey = 'settings.glass_navigation';

  final SharedPreferences _preferences;

  const AppSettingsStorage(this._preferences);

  /// [ThemeMode.system] until the user chooses light or dark.
  ThemeMode readThemeMode() {
    final saved = _preferences.getString(_themeModeKey);
    return ThemeMode.values.where((mode) => mode.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> writeThemeMode(ThemeMode mode) =>
      _preferences.setString(_themeModeKey, mode.name);

  /// Null until the user chooses a language: the phone's language is used.
  Locale? readLocale() {
    final saved = _preferences.getString(_languageKey);
    return saved == null ? null : Locale(saved);
  }

  Future<void> writeLocale(Locale locale) =>
      _preferences.setString(_languageKey, locale.languageCode);

  /// Whether a chat notification shows what the message says. On until the
  /// user turns it off: anyone who can see the lock screen can read it.
  bool readShowNotificationText() =>
      _preferences.getBool(_showNotificationTextKey) ?? true;

  Future<void> writeShowNotificationText(bool show) =>
      _preferences.setBool(_showNotificationTextKey, show);

  /// Whether a phone whose own interface is glass shows the app's navigation
  /// in glass too. On until the user turns it off.
  bool readGlassNavigation() =>
      _preferences.getBool(_glassNavigationKey) ?? true;

  Future<void> writeGlassNavigation(bool enabled) =>
      _preferences.setBool(_glassNavigationKey, enabled);
}
