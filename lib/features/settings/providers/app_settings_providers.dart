import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/features/settings/data/app_settings_storage.dart';

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

/// Whether chat notifications show the message text (see
/// [AppSettingsStorage.readShowNotificationText]).
final showNotificationTextProvider =
    StateNotifierProvider<ShowNotificationTextNotifier, bool>(
      (ref) =>
          ShowNotificationTextNotifier(ref.watch(appSettingsStorageProvider)),
    );

class ShowNotificationTextNotifier extends StateNotifier<bool> {
  final AppSettingsStorage _storage;

  ShowNotificationTextNotifier(this._storage)
    : super(_storage.readShowNotificationText());

  Future<void> select(bool show) async {
    state = show;
    await _storage.writeShowNotificationText(show);
  }
}

class LocaleNotifier extends StateNotifier<Locale?> {
  final AppSettingsStorage _storage;

  LocaleNotifier(this._storage) : super(_storage.readLocale());

  Future<void> select(Locale locale) async {
    state = locale;
    await _storage.writeLocale(locale);
  }
}

/// Whether the navigation is drawn in glass on phones that support it (see
/// [AppSettingsStorage.readGlassNavigation]).
final glassNavigationProvider =
    StateNotifierProvider<GlassNavigationNotifier, bool>(
      (ref) => GlassNavigationNotifier(ref.watch(appSettingsStorageProvider)),
    );

class GlassNavigationNotifier extends StateNotifier<bool> {
  final AppSettingsStorage _storage;

  GlassNavigationNotifier(this._storage)
    : super(_storage.readGlassNavigation());

  Future<void> select(bool enabled) async {
    state = enabled;
    await _storage.writeGlassNavigation(enabled);
  }
}
