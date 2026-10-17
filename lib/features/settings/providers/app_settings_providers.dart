import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/features/settings/data/app_settings_storage.dart';

/// Overridden in `main.dart`: the saved settings are read before the first
/// frame, so the app never starts in the wrong theme or language.
final appSettingsStorageProvider = Provider<AppSettingsStorage>((ref) {
  throw UnimplementedError('Override appSettingsStorageProvider in main.dart');
});

/// Light, dark, or whatever the phone is set to.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref.watch(appSettingsStorageProvider)),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final AppSettingsStorage _storage;

  ThemeModeNotifier(this._storage) : super(_storage.readThemeMode());

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await _storage.writeThemeMode(mode);
  }
}

/// The language the user picked, or null to follow the phone's language.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(ref.watch(appSettingsStorageProvider)),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  final AppSettingsStorage _storage;

  LocaleNotifier(this._storage) : super(_storage.readLocale());

  Future<void> select(Locale locale) async {
    state = locale;
    await _storage.writeLocale(locale);
  }
}
