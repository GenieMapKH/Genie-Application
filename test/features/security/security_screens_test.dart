import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/security/data/repositories/account_repository.dart';
import 'package:tilomnov/features/security/data/repositories/session_repository.dart';
import 'package:tilomnov/features/security/presentation/screens/account_removal_page.dart';
import 'package:tilomnov/features/security/presentation/screens/change_password_page.dart';
import 'package:tilomnov/features/security/presentation/screens/devices_page.dart';
import 'package:tilomnov/features/security/presentation/screens/security_page.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';

import '../../support/test_app.dart';

UserProfile _profile({String? firebaseUid, bool hasPassword = true}) =>
    UserProfile(
      id: 'u1',
      role: 'user',
      createdAt: DateTime(2026),
      firebaseUid: firebaseUid,
      hasPassword: hasPassword,
    );

Override _signedIn({String? firebaseUid, bool hasPassword = true}) =>
    userProfileProvider.overrideWith(
      (ref) async =>
          _profile(firebaseUid: firebaseUid, hasPassword: hasPassword),
    );

/// [established] is false for a device that signed in less than a day ago.
String _sessionsJson({bool established = true}) {
  final recently = DateTime.now().toUtc().subtract(const Duration(hours: 3));
  return '{"sessions":[{"id":"s1","deviceName":"Pixel 8","platform":"Android 15",'
      '"location":"Phnom Penh, Cambodia","signedInAt":"2026-03-01T08:00:00.000Z",'
      '"lastUsedAt":"${recently.toIso8601String()}","current":true},'
      '{"id":"s2","deviceName":null,"platform":"Windows 11","location":null,'
      '"signedInAt":"2026-02-01T08:00:00.000Z",'
      '"lastUsedAt":"${recently.toIso8601String()}","current":false}],'
      '"canSignOutOthers":$established,'
      '"canSignOutOthersFrom":"2026-03-02T08:00:00.000Z"}';
}

/// Records which PINs and password were asked for, without doing any key
/// work.
/// Toasts stay for a few seconds; a test must not end while one is showing.
Future<void> _letToastsLeave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'security offers account controls without chat PIN or key setup',
    (tester) async {
      await pumpTestApp(tester, const SecurityPage(), overrides: [_signedIn()]);
      expect(find.text('Logged-in devices'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Change chat PIN'), findsNothing);
      expect(find.text('Reset encryption keys'), findsNothing);
    },
  );

  group('logged-in devices', () {
    testWidgets('lists each device with its place and last use', (
      tester,
    ) async {
      final server = StubServer.always(200, _sessionsJson());
      await pumpTestApp(
        tester,
        const DevicesPage(),
        overrides: [
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(server.dio),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('This device'), findsOneWidget);
      expect(find.text('Android 15 · Phnom Penh, Cambodia'), findsOneWidget);
      expect(find.text('Active now'), findsOneWidget);
      // The other device said little about itself.
      expect(find.text('Unknown device'), findsOneWidget);
      expect(find.text('Windows 11 · Unknown location'), findsOneWidget);
      expect(find.text('Last used 3 hours ago'), findsOneWidget);
      // Only the other device can be signed out from here.
      expect(find.widgetWithText(TextButton, 'Sign out'), findsOneWidget);
      expect(find.text('Sign out of all devices'), findsOneWidget);
    });

    testWidgets('signs one device out after confirming', (tester) async {
      final server = StubServer(
        (request) => (200, request.method == 'GET' ? _sessionsJson() : '{}'),
      );
      await pumpTestApp(
        tester,
        const DevicesPage(),
        overrides: [
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(server.dio),
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out this device?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
      await tester.pumpAndSettle();

      expect(server.requests.last.method, 'DELETE');
      expect(server.requests.last.path, '/auth/sessions/s2');
      expect(find.text('Unknown device'), findsNothing);
      expect(find.text('Pixel 8'), findsOneWidget);
      await _letToastsLeave(tester);
    });

    testWidgets('says so when the list cannot be loaded', (tester) async {
      await pumpTestApp(
        tester,
        const DevicesPage(),
        overrides: [
          sessionRepositoryProvider.overrideWithValue(
            SessionRepository(StubServer.always(500).dio),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load your devices'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('change password', () {
    Future<StubServer> open(WidgetTester tester, int status) async {
      final server = StubServer.always(status);
      await pumpTestApp(
        tester,
        const ChangePasswordPage(),
        overrides: [
          _signedIn(),
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(server.dio),
          ),
        ],
      );
      return server;
    }

    Future<void> submit(
      WidgetTester tester, {
      required String current,
      required String next,
      required String confirmation,
    }) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), current);
      await tester.enterText(fields.at(1), next);
      await tester.enterText(fields.at(2), confirmation);
      await tester.tap(find.text('Change password').last);
      await tester.pumpAndSettle();
    }

    testWidgets('checks what was typed before asking the server', (
      tester,
    ) async {
      final server = await open(tester, 200);

      await submit(tester, current: '', next: '', confirmation: '');
      expect(find.text('Enter your current password.'), findsOneWidget);

      await submit(
        tester,
        current: 'old-pass',
        next: 'short',
        confirmation: '',
      );
      expect(find.text('Use at least 8 characters.'), findsOneWidget);

      await submit(
        tester,
        current: 'old-pass',
        next: 'new-password',
        confirmation: 'new-passwrod',
      );
      expect(find.text('The two passwords do not match.'), findsOneWidget);
      expect(server.requests, isEmpty);
    });

    testWidgets('a wrong current password is reported under that field', (
      tester,
    ) async {
      final server = await open(tester, 403);

      await submit(
        tester,
        current: 'guess',
        next: 'new-password',
        confirmation: 'new-password',
      );

      expect(find.text('The current password is incorrect.'), findsOneWidget);
      expect(server.requests.single.path, '/auth/change-password');
    });
  });

  group('deactivate or delete account', () {
    Future<StubServer> open(
      WidgetTester tester, {
      required int status,
      String? firebaseUid,
    }) async {
      final server = StubServer.always(status);
      await pumpTestApp(
        tester,
        const AccountRemovalPage(),
        overrides: [
          _signedIn(firebaseUid: firebaseUid),
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(server.dio),
          ),
        ],
      );
      await tester.pumpAndSettle();
      return server;
    }

    testWidgets('explains both choices', (tester) async {
      await open(tester, status: 200);

      expect(find.textContaining('Sign in to restore them'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
    });

    testWidgets(
      'deleting needs the password, and a wrong one deletes nothing',
      (tester) async {
        final server = await open(tester, status: 403);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm with Google'), findsNothing);

        // Without a password nothing is sent.
        await tester.tap(find.text('Delete forever'));
        await tester.pumpAndSettle();
        expect(find.text('Enter your password.'), findsOneWidget);
        expect(server.requests, isEmpty);

        await tester.enterText(find.byType(TextField), 'guess');
        await tester.tap(find.text('Delete forever'));
        await tester.pumpAndSettle();

        expect(server.requests.single.path, '/auth/account/delete');
        expect(server.requests.single.body, {'password': 'guess'});
        expect(find.text('The password is incorrect.'), findsOneWidget);
        // Still on the dialog: the account was not removed.
        expect(find.byType(AppDialog), findsOneWidget);
      },
    );

    testWidgets('a Google account may confirm with Google instead', (
      tester,
    ) async {
      await open(tester, status: 200, firebaseUid: 'fb1');

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Deactivate account'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm with Google'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });
  });
}
