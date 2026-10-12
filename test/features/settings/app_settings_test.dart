import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/core/theme/app_theme.dart';
import 'package:genie/features/settings/data/app_settings_storage.dart';
import 'package:genie/features/settings/providers/app_settings_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _containerWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  final storage = AppSettingsStorage(await SharedPreferences.getInstance());
  final container = ProviderContainer(
    overrides: [appSettingsStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('saved settings', () {
    test('follow the phone until the user picks something', () async {
      final container = await _containerWith({});

      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(container.read(localeProvider), isNull);
    });

    test('the picked theme and language survive a restart', () async {
      final container = await _containerWith({});
      await container.read(themeModeProvider.notifier).select(ThemeMode.dark);
      await container.read(localeProvider.notifier).select(AppLanguages.khmer);

      // A new container reads the same storage, as the next app start would.
      final restarted = ProviderContainer(
        overrides: [
          appSettingsStorageProvider.overrideWithValue(
            AppSettingsStorage(await SharedPreferences.getInstance()),
          ),
        ],
      );
      addTearDown(restarted.dispose);

      expect(restarted.read(themeModeProvider), ThemeMode.dark);
      expect(restarted.read(localeProvider), AppLanguages.khmer);
    });

    test(
      'a value this version does not know falls back to the phone',
      () async {
        final container = await _containerWith({
          'settings.theme_mode': 'sepia',
        });

        expect(container.read(themeModeProvider), ThemeMode.system);
      },
    );
  });

  group('themes', () {
    // A widget test: building a theme asks google_fonts for the Inter font.
    testWidgets('each carries its own palette', (tester) async {
      expect(AppTheme.light.extension<AppColors>(), AppColors.light);
      expect(AppTheme.dark.extension<AppColors>(), AppColors.dark);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.dark.background);
    });

    test('text stays readable on its background in both', () {
      for (final colors in [AppColors.light, AppColors.dark]) {
        for (final text in [colors.textPrimary, colors.textMuted]) {
          final contrast = _contrast(text, colors.background);
          expect(contrast, greaterThan(4.5), reason: '$text on $colors');
        }
      }
    });
  });

  group('translations', () {
    test('Khmer is offered next to English', () {
      expect(AppLocalizations.supportedLocales, AppLanguages.all);
      expect(lookupAppLocalizations(AppLanguages.khmer).accountTitle, 'គណនី');
      expect(AppLanguages.nativeName(AppLanguages.khmer), 'ភាសាខ្មែរ');
    });
  });
}

/// WCAG contrast ratio between two colours (1 = none, 21 = black on white).
double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
