import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the look and language the user picked, on this device.
/// Nothing is stored until they pick something, so by default the app
/// follows the phone.
class AppSettingsStorage {
  static const _themeModeKey = 'settings.theme_mode';
  static const _languageKey = 'settings.language';

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
}
