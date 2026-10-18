import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strings that are the same in every language: an example address and a
/// coordinate system's name.
const _sameInEveryLanguage = {'authExampleGmailCom', 'homeCrsWgs84UtmZone48p'};

Map<String, dynamic> _strings(String locale) {
  final arb = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync());
  return {
    for (final entry in (arb as Map<String, dynamic>).entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value,
  };
}

void main() {
  final english = _strings('en');
  final khmer = _strings('km');

  test('every English string has a Khmer one', () {
    final missing = english.keys.where((key) => !khmer.containsKey(key));

    expect(missing, isEmpty);
  });

  test('no Khmer string is just the English one copied', () {
    final untranslated = english.keys.where(
      (key) =>
          !_sameInEveryLanguage.contains(key) && khmer[key] == english[key],
    );

    expect(untranslated, isEmpty);
  });
}
