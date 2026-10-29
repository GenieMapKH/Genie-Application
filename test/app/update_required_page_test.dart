import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/app/update/update_required_page.dart';
import 'package:tilomnov/l10n/l10n.dart';

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const UpdateRequiredPage(),
);

void main() {
  testWidgets('asks for an update, in English', (tester) async {
    await tester.pumpWidget(_app(AppLanguages.english));
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.textContaining('Please update the app'), findsOneWidget);
  });

  testWidgets('asks for an update, in Khmer', (tester) async {
    await tester.pumpWidget(_app(AppLanguages.khmer));
    await tester.pumpAndSettle();

    expect(find.text('តម្រូវឱ្យធ្វើបច្ចុប្បន្នភាព'), findsOneWidget);
  });
}
