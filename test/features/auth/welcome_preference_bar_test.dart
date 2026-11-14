import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/auth/presentation/widgets/welcome_preference_bar.dart';
import 'package:tilomnov/features/settings/data/app_settings_storage.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'the flag switches the language and the icon switches the theme',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = AppSettingsStorage(await SharedPreferences.getInstance());
      final container = ProviderContainer(
        overrides: [appSettingsStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              locale: ref.watch(localeProvider),
              themeMode: ref.watch(themeModeProvider),
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: WelcomePreferenceBar()),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('ភាសាខ្មែរ'));
      await tester.pumpAndSettle();
      expect(container.read(localeProvider), AppLanguages.khmer);

      await tester.tap(find.byTooltip('English'));
      await tester.pumpAndSettle();
      expect(container.read(localeProvider), AppLanguages.english);

      await tester.tap(find.byIcon(LucideIcons.sun));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await tester.tap(find.byIcon(LucideIcons.moon));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.light);
    },
  );
}
