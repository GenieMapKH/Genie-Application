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

/// Watches the profile the way the rest of the app does from launch, and
/// shows the account screen only once "Open" is tapped.
class _OpenedLater extends ConsumerStatefulWidget {
  const _OpenedLater();

  @override
  ConsumerState<_OpenedLater> createState() => _OpenedLaterState();
}

class _OpenedLaterState extends ConsumerState<_OpenedLater> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileProvider);
    if (_open) return const UserProfilePage();
    return TextButton(
      onPressed: () => setState(() => _open = true),
      child: const Text('Open'),
    );
  }
}

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

    testWidgets('a failure from before it was opened is retried at once', (
      tester,
    ) async {
      var attempts = 0;
      await pumpTestApp(
        tester,
        const _OpenedLater(),
        overrides: [
          userProfileProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) throw Exception('offline at launch');
            return _profile;
          }),
        ],
      );
      await tester.pumpAndSettle();
      expect(attempts, 1);

      await tester.tap(find.text('Open'));
      await tester.pump();
      // Never greets with the old error: it is already trying again.
      expect(find.text('Could not load profile'), findsNothing);
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('Sokha Chan'), findsOneWidget);
    });

    testWidgets('a failure on opening offers Retry, which tries again', (
      tester,
    ) async {
      var attempts = 0;
      await pumpTestApp(
        tester,
        const UserProfilePage(),
        overrides: [
          userProfileProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) throw Exception('offline');
            return _profile;
          }),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load profile'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Sokha Chan'), findsOneWidget);
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

    /// Answers `GET /users/username-available` with [checkAnswer] and
    /// `PATCH /users/me` with [saveStatus].
    StubServer usernameServer({
      required String checkAnswer,
      int saveStatus = 200,
    }) {
      return StubServer(
        (request) => request.method == 'GET'
            ? (200, checkAnswer)
            : (
                saveStatus,
                '{"id":"u1","role":"user","createdAt":"2026-01-01T00:00:00.000Z"}',
              ),
      );
    }

    Future<void> typeUsername(WidgetTester tester, String text) async {
      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), text);
      // A pause in typing is what triggers the check.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'a username someone else has is refused before Save is pressed',
      (tester) async {
        final server = usernameServer(
          checkAnswer: '{"username":"dara","available":false,"reason":"taken"}',
        );
        await pumpTestApp(
          tester,
          const PersonalInfoPage(),
          overrides: _signedIn(server: server),
        );

        await typeUsername(tester, 'dara');

        expect(find.text('This username is already taken.'), findsOneWidget);
        // Asked the server, with the name as it would be saved.
        expect(server.requests.single.method, 'GET');
        expect(server.requests.single.path, '/users/username-available');
        // Save is not offered, so nothing is sent.
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(server.requests, hasLength(1));
      },
    );

    testWidgets('a free username says so, and saves', (tester) async {
      final server = usernameServer(
        checkAnswer: '{"username":"dara","available":true,"reason":null}',
      );
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(server: server),
      );

      await typeUsername(tester, 'Dara');
      expect(find.text('This username is available.'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(server.requests.last.method, 'PATCH');
      expect(server.requests.last.body, {'username': 'dara'});
      expect(find.byType(AlertDialog), findsNothing);
      await _letToastsLeave(tester);
    });

    testWidgets(
      'a username taken between the check and Save is still refused',
      (tester) async {
        // Free when asked, taken by someone else a moment later.
        final server = usernameServer(
          checkAnswer: '{"username":"dara","available":true,"reason":null}',
          saveStatus: 409,
        );
        await pumpTestApp(
          tester,
          const PersonalInfoPage(),
          overrides: _signedIn(server: server),
        );

        await typeUsername(tester, 'dara');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('This username is already taken.'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets('your own current username is not asked about', (tester) async {
      final server = StubServer.always(200);
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(server: server),
      );

      await typeUsername(tester, 'sokha');

      expect(server.requests, isEmpty);
      expect(find.text('This username is already taken.'), findsNothing);
    });

    testWidgets('can still be saved when the check could not be made', (
      tester,
    ) async {
      final server = StubServer(
        (request) => request.method == 'GET'
            ? (500, '{}')
            : (
                200,
                '{"id":"u1","role":"user","createdAt":"2026-01-01T00:00:00.000Z"}',
              ),
      );
      await pumpTestApp(
        tester,
        const PersonalInfoPage(),
        overrides: _signedIn(server: server),
      );

      await typeUsername(tester, 'dara');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The server decides at save, which is the check that counts.
      expect(server.requests.last.method, 'PATCH');
      await _letToastsLeave(tester);
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
      await tester.pumpAndSettle();

      // Said as it is typed, and never sent anywhere.
      expect(find.textContaining('Use 3 to 30 lowercase'), findsWidgets);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
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
