import 'package:flutter/widgets.dart';

import 'package:genie/l10n/generated/app_localizations.dart';

export 'package:genie/l10n/generated/app_localizations.dart';

/// The languages the app is translated into, in the order the picker shows them.
/// To add one: add `app_<code>.arb` next to `app_en.arb` and list it here.
abstract final class AppLanguages {
  static const english = Locale('en');
  static const khmer = Locale('km');

  static const all = [english, khmer];

  /// What a language calls itself, so it can be found by someone who cannot
  /// read the language the app is currently in.
  static String nativeName(Locale locale) => switch (locale.languageCode) {
    'km' => 'ភាសាខ្មែរ',
    _ => 'English',
  };
}

final AppLocalizations _english = lookupAppLocalizations(AppLanguages.english);

extension AppLocalizationsContext on BuildContext {
  /// The app's texts in the language in use. Falls back to English where no
  /// translations are installed (a bare `MaterialApp` in a widget test).
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _english;
}
