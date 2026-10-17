import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/security/data/repositories/account_repository.dart';
import 'package:genie/features/security/data/repositories/session_repository.dart';
import 'package:genie/features/security/presentation/screens/account_removal_page.dart';
import 'package:genie/features/security/presentation/screens/change_password_page.dart';
import 'package:genie/features/security/presentation/screens/devices_page.dart';
import 'package:genie/features/security/presentation/screens/security_page.dart';
import 'package:genie/features/security/presentation/view_models/security_providers.dart';

import '../../support/test_app.dart';

UserProfile _profile({String? firebaseUid}) => UserProfile(
  id: 'u1',
  role: 'user',
  createdAt: DateTime(2026),
  firebaseUid: firebaseUid,
);

Override _signedIn({String? firebaseUid}) => userProfileProvider.overrideWith(
  (ref) async => _profile(firebaseUid: firebaseUid),
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

/// Records which PINs the reset asked for, without doing any key work.
class _FakeKeyManager extends Fake implements E2eeKeyManager {
  String? currentPin;
  String? newPin;

  @override
  Future<ResetKeysResult> resetKeys(
    String userId, {
    required PinRequest askCurrentPin,
    required PinRequest askNewPin,
  }) async {
    currentPin = await askCurrentPin();
    if (currentPin == null) return ResetKeysResult.cancelled;
    newPin = await askNewPin();
    return newPin == null ? ResetKeysResult.cancelled : ResetKeysResult.reset;
  }
}

/// Toasts stay for a few seconds; a test must not end while one is showing.
Future<void> _letToastsLeave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('security screen', () {
    testWidgets('gathers encryption, sign-in and account tools', (
      tester,
    ) async {
      await pumpTestApp(tester, const SecurityPage(), overrides: [_signedIn()]);

      // The backup PIN is optional: it can be added and removed here.
      expect(find.textContaining('A backup PIN is optional'), findsOneWidget);
      for (final row in [
        'Set up backup PIN',
        'Change backup PIN',
        'Forgot backup PIN',
        'Turn off backup PIN',
        'Reset encryption keys',
        'Change password',
        'Logged-in devices',
        'Deactivate or delete account',
      ]) {
        await tester.scrollUntilVisible(find.text(row), 100);
        expect(find.text(row), findsOneWidget);
      }
    });

    testWidgets('resetting keys asks for the current PIN before a new one', (
      tester,
    ) async {
      final manager = _FakeKeyManager();
      await pumpTestApp(
        tester,
        const SecurityPage(),
        overrides: [
          _signedIn(),
          e2eeKeyManagerProvider.overrideWithValue(manager),
        ],
      );

      await tester.tap(find.text('Reset encryption keys'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset keys'));
      await tester.pumpAndSettle();

      expect(find.text('Enter current PIN'), findsOneWidget);
      expect(find.text('PIN for the new keys'), findsNothing);

      await tester.enterText(find.byType(TextField), '482915');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(manager.currentPin, '482915');
      expect(find.text('PIN for the new keys'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '739206');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(manager.newPin, '739206');
      expect(find.text('Encryption keys reset.'), findsOneWidget);
      await _letToastsLeave(tester);
    });

    testWidgets('cancelling the current PIN resets nothing', (tester) async {
      final manager = _FakeKeyManager();
      await pumpTestApp(
        tester,
        const SecurityPage(),
        overrides: [
          _signedIn(),
          e2eeKeyManagerProvider.overrideWithValue(manager),
        ],
      );

      await tester.tap(find.text('Reset encryption keys'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset keys'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(manager.newPin, isNull);
      expect(find.text('Encryption keys reset.'), findsNothing);
    });
  });

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

      expect(find.textContaining('Nothing is deleted'), findsOneWidget);
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
        expect(find.byType(AlertDialog), findsOneWidget);
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
