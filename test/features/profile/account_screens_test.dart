import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/screens/personal_info_page.dart';
import 'package:genie/features/profile/presentation/screens/user_profile_page.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_app.dart';

final _profile = UserProfile(
  id: 'u1',
  email: 'sokha@example.com',
  username: 'sokha',
  name: 'Sokha Chan',
  firstName: 'Sokha',
  sex: Sex.female,
  role: 'user',
  createdAt: DateTime(2026),
);

List<Override> _signedIn({StubServer? server}) => [
  userProfileProvider.overrideWith((ref) async => _profile),
  if (server != null)
    userRepositoryProvider.overrideWithValue(UserRepository(server.dio)),
];

/// Toasts stay for a few seconds; a test must not end while one is showing.
Future<void> _letToastsLeave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('account screen', () {
    testWidgets('shows who is signed in and the way into each setting', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const UserProfilePage(),
        overrides: _signedIn(),
      );

      expect(find.text('Sokha Chan'), findsOneWidget);
      expect(find.text('@sokha'), findsOneWidget);
      for (final row in [
        'Personal information',
        'Security',
        'Appearance',
        'Language',
      ]) {
        expect(find.text(row), findsOneWidget);
      }
      // The personal details and the security tools have screens of their own.
      expect(find.text('sokha@example.com'), findsNothing);
      expect(find.textContaining('PIN'), findsNothing);
    });

    testWidgets('choosing Dark repaints the app and is remembered', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const UserProfilePage(),
        overrides: _signedIn(),
      );
      Brightness brightness() =>
          Theme.of(tester.element(find.byType(UserProfilePage))).brightness;
      expect(brightness(), Brightness.light);

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(brightness(), Brightness.dark);
      expect(find.text('Dark'), findsOneWidget);
      final saved = await SharedPreferences.getInstance();
      expect(saved.getString('settings.theme_mode'), 'dark');
    });

    testWidgets('choosing Khmer translates the app and is remembered', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const UserProfilePage(),
        overrides: _signedIn(),
      );

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ភាសាខ្មែរ'));
      await tester.pumpAndSettle();

      expect(find.text('ព័ត៌មានផ្ទាល់ខ្លួន'), findsOneWidget);
      expect(find.text('សុវត្ថិភាព'), findsOneWidget);
      expect(find.text('Personal information'), findsNothing);
      final saved = await SharedPreferences.getInstance();
      expect(saved.getString('settings.language'), 'km');
    });

    testWidgets('opens in the language saved last time', (tester) async {
      await pumpTestApp(
        tester,
        const UserProfilePage(),
        overrides: _signedIn(),
        savedSettings: {'settings.language': 'km'},
      );
      await tester.pumpAndSettle();

      expect(find.text('គណនី'), findsWidgets);
    });
  });

  group('personal information', () {
    testWidgets('lists every detail, saying which are not set', (tester) async {
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(),
      );

      expect(find.text('@sokha'), findsOneWidget);
      expect(find.text('Sokha Chan'), findsOneWidget);
      expect(find.text('Sokha'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('sokha@example.com'), findsOneWidget);
      // Last name and phone number.
      expect(find.text('Not set'), findsNWidgets(2));
    });

    testWidgets('a username someone else has is refused with a reason', (
      tester,
    ) async {
      final server = StubServer.always(409);
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(server: server),
      );

      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'dara');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('This username is already taken.'), findsOneWidget);
      expect(server.requests.single.body, {'username': 'dara'});
    });

    testWidgets('a badly formed username never reaches the server', (
      tester,
    ) async {
      final server = StubServer.always(200);
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(server: server),
      );

      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Dara Sok');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Use 3 to 30 lowercase'), findsWidgets);
      expect(server.requests, isEmpty);
    });

    testWidgets('a name is saved as typed and the dialog closes', (
      tester,
    ) async {
      final server = StubServer.always(
        200,
        '{"id":"u1","role":"user","createdAt":"2026-01-01T00:00:00.000Z"}',
      );
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(server: server),
      );

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'សុខា ចាន់');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(server.requests.single.body, {'name': 'សុខា ចាន់'});
      expect(find.byType(AlertDialog), findsNothing);
      await _letToastsLeave(tester);
    });

    testWidgets('sex is picked from a list', (tester) async {
      final server = StubServer.always(
        200,
        '{"id":"u1","role":"user","createdAt":"2026-01-01T00:00:00.000Z"}',
      );
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(server: server),
      );

      await tester.tap(find.text('Sex'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      expect(server.requests.single.body, {'sex': 'male'});
    });
  });
}
