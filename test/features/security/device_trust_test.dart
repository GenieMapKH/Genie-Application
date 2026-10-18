import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/e2ee/e2ee_key_manager.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/security/data/known_devices_storage.dart';
import 'package:genie/features/security/data/models/device_session.dart';
import 'package:genie/features/security/data/repositories/account_repository.dart';
import 'package:genie/features/security/data/repositories/session_repository.dart';
import 'package:genie/features/security/presentation/screens/change_password_page.dart';
import 'package:genie/features/security/presentation/screens/create_password_page.dart';
import 'package:genie/features/security/presentation/screens/devices_page.dart';
import 'package:genie/features/security/presentation/screens/security_page.dart';
import 'package:genie/features/security/presentation/view_models/account_security_controller.dart';
import 'package:genie/features/security/presentation/view_models/new_sign_in_detector.dart';
import 'package:genie/features/security/presentation/view_models/security_providers.dart';
import 'package:genie/features/security/presentation/widgets/new_sign_in_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_app.dart';

UserProfile _profile({String? firebaseUid, bool hasPassword = true}) {
  return UserProfile(
    id: 'u1',
    role: 'user',
    createdAt: DateTime(2026),
    firebaseUid: firebaseUid,
    hasPassword: hasPassword,
  );
}

Override _signedInAs(UserProfile profile) =>
    userProfileProvider.overrideWith((ref) async => profile);

String _device(String id, {bool current = false, String? name}) {
  final now = DateTime.now().toUtc().toIso8601String();
  final deviceName = name == null ? 'null' : '"$name"';
  return '{"id":"$id","deviceName":$deviceName,"platform":"Android 15",'
      '"location":"Siem Reap, Cambodia","signedInAt":"$now",'
      '"lastUsedAt":"$now","current":$current}';
}

String _devices(List<String> devices, {bool canSignOutOthers = true}) {
  return '{"sessions":[${devices.join(',')}],'
      '"canSignOutOthers":$canSignOutOthers,'
      '"canSignOutOthersFrom":"2026-03-02T08:00:00.000Z"}';
}

/// A device list the test can change, as the server's changes when someone
/// signs in.
class _Sessions extends Fake implements SessionRepository {
  List<String> devices;

  _Sessions(this.devices);

  @override
  Future<DeviceList> fetchSessions() async {
    return SessionRepository(
      StubServer.always(200, _devices(devices)).dio,
    ).fetchSessions();
  }
}

/// Says whether this device holds the account's keys, without any key work.
class _FakeKeyManager extends Fake implements E2eeKeyManager {
  final bool holdsKeys;

  _FakeKeyManager({required this.holdsKeys});

  @override
  Future<bool> holdsCurrentKeys(String userId) async => holdsKeys;
}

void main() {
  group('a device that signed in less than a day ago', () {
    testWidgets('sees the other devices but cannot sign them out', (
      tester,
    ) async {
      final server = StubServer.always(
        200,
        _devices([
          _device('s1', current: true, name: 'New phone'),
          _device('s2', name: 'Old phone'),
        ], canSignOutOthers: false),
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

      expect(find.text('Old phone'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign out'), findsNothing);
      expect(find.text('Sign out of all devices'), findsNothing);
      // It is told why, and from when it can.
      expect(
        find.textContaining('only after it has been signed in for a day'),
        findsOneWidget,
      );
    });
  });

  group('one-day rule on account changes', () {
    const tooNew =
        '{"statusCode":403,"code":"DEVICE_TOO_NEW","message":"too new"}';

    test('is told apart from a wrong password', () async {
      final refused = AccountSecurityController(
        AccountRepository(StubServer.always(403, tooNew).dio),
      );
      final wrongPassword = AccountSecurityController(
        AccountRepository(StubServer.always(403, '{"statusCode":403}').dio),
      );

      expect(
        await refused.changePassword(current: 'right', next: 'new-password'),
        AccountActionResult.deviceTooNew,
      );
      expect(
        await refused.delete(const IdentityProof.password('right')),
        AccountActionResult.deviceTooNew,
      );
      expect(
        await wrongPassword.changePassword(current: 'x', next: 'new-password'),
        AccountActionResult.identityRejected,
      );
    });

    testWidgets('changing the password says why it was refused', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const ChangePasswordPage(),
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(StubServer.always(403, tooNew).dio),
          ),
        ],
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'my-password');
      await tester.enterText(fields.at(1), 'new-password');
      await tester.enterText(fields.at(2), 'new-password');
      await tester.tap(find.text('Change password').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('signed in less than a day ago'),
        findsOneWidget,
      );
      // Not blamed on the password, which was right.
      expect(find.text('The current password is incorrect.'), findsNothing);
    });
  });

  group('NewSignInDetector', () {
    late _Sessions sessions;
    late NewSignInDetector detector;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sessions = _Sessions([_device('mine', current: true)]);
      detector = NewSignInDetector(sessions, KnownDevicesStorage());
    });

    test(
      'reports nothing the first time: those devices were there before',
      () async {
        sessions.devices.add(_device('tablet'));

        expect(await detector.check('u1'), isEmpty);
      },
    );

    test('reports a device that signs in afterwards', () async {
      await detector.check('u1');
      sessions.devices.add(_device('stranger', name: 'Unknown PC'));

      final unseen = await detector.check('u1');

      expect(unseen.single.deviceName, 'Unknown PC');
    });

    test(
      'keeps reporting it until the user has seen it, then never again',
      () async {
        await detector.check('u1');
        sessions.devices.add(_device('stranger'));

        expect(await detector.check('u1'), hasLength(1));
        final unseen = await detector.check('u1');
        expect(unseen, hasLength(1));

        await detector.acknowledge('u1', unseen);
        expect(await detector.check('u1'), isEmpty);
      },
    );

    test('never reports the device that is looking', () async {
      await detector.check('u1');
      sessions.devices = [_device('renewed', current: true)];

      expect(await detector.check('u1'), isEmpty);
    });

    test('keeps the lists of two accounts on one phone apart', () async {
      await detector.check('u1');
      sessions.devices.add(_device('stranger'));

      // The second account looks for the first time: nothing to report.
      expect(await detector.check('u2'), isEmpty);
      expect(await detector.check('u1'), hasLength(1));
    });
  });

  group('new sign-in alert', () {
    testWidgets('tells the user about a device that signed in', (tester) async {
      final sessions = _Sessions([
        _device('mine', current: true),
        _device('stranger', name: 'Unknown PC'),
      ]);

      await pumpTestApp(
        tester,
        const Scaffold(body: NewSignInAlert()),
        overrides: [
          _signedInAs(_profile()),
          sessionRepositoryProvider.overrideWithValue(sessions),
        ],
        // This phone has looked before and knew only itself.
        savedSettings: {
          'security.known_devices.u1': ['mine'],
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('New sign-in to your account'), findsOneWidget);
      expect(find.text('Unknown PC'), findsOneWidget);
      expect(find.text('Android 15 · Siem Reap, Cambodia'), findsOneWidget);

      await tester.tap(find.text('It was me'));
      await tester.pumpAndSettle();

      expect(find.text('New sign-in to your account'), findsNothing);
      final known = await KnownDevicesStorage().read('u1');
      expect(known, contains('stranger'));
    });

    testWidgets('stays quiet when nothing is new', (tester) async {
      await pumpTestApp(
        tester,
        const Scaffold(body: NewSignInAlert()),
        overrides: [
          _signedInAs(_profile()),
          sessionRepositoryProvider.overrideWithValue(
            _Sessions([_device('mine', current: true)]),
          ),
        ],
        savedSettings: {
          'security.known_devices.u1': ['mine'],
        },
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('password of an account that signs in with Google', () {
    testWidgets('is created, not changed, while there is none', (tester) async {
      await pumpTestApp(
        tester,
        const SecurityPage(),
        overrides: [
          _signedInAs(_profile(firebaseUid: 'fb1', hasPassword: false)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Create password'), findsOneWidget);
      expect(find.text('Change password'), findsNothing);
    });

    testWidgets('is changed once it exists', (tester) async {
      await pumpTestApp(
        tester,
        const SecurityPage(),
        overrides: [_signedInAs(_profile(firebaseUid: 'fb1'))],
      );
      await tester.pumpAndSettle();

      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Create password'), findsNothing);
    });

    testWidgets('must be long enough and typed the same twice', (tester) async {
      final server = StubServer.always(200);
      await pumpTestApp(
        tester,
        const CreatePasswordPage(),
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(server.dio),
          ),
        ],
      );
      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(0), 'short');
      await tester.tap(find.text('Confirm with Google and create'));
      await tester.pumpAndSettle();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);

      await tester.enterText(fields.at(0), 'long-enough');
      await tester.enterText(fields.at(1), 'long-enouhg');
      await tester.tap(find.text('Confirm with Google and create'));
      await tester.pumpAndSettle();
      expect(find.text('The two passwords do not match.'), findsOneWidget);
      expect(server.requests, isEmpty);
    });

    test('is sent with the Google confirmation', () async {
      final server = StubServer.always(200);

      final result =
          await AccountSecurityController(
            AccountRepository(server.dio),
          ).createPassword(
            googleIdToken: 'fresh-id-token',
            password: 'my-first-password',
          );

      expect(result, AccountActionResult.done);
      expect(server.requests.single.path, '/auth/account/password');
      expect(server.requests.single.body, {
        'idToken': 'fresh-id-token',
        'newPassword': 'my-first-password',
      });
    });
  });

  // The account password proves a forgotten chat PIN is the owner's: an
  // account that signs in with Google alone creates one first.
  group('forgotten chat PIN of a Google-only account', () {
    Future<void> open(WidgetTester tester, {required bool holdsKeys}) async {
      await pumpTestApp(
        tester,
        const SecurityPage(),
        overrides: [
          _signedInAs(_profile(firebaseUid: 'fb1', hasPassword: false)),
          e2eeKeyManagerProvider.overrideWithValue(
            _FakeKeyManager(holdsKeys: holdsKeys),
          ),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot chat PIN'));
      await tester.pumpAndSettle();
    }

    testWidgets('first creates a password, and no history is lost', (
      tester,
    ) async {
      await open(tester, holdsKeys: true);
      expect(find.textContaining('nothing is lost'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePasswordPage), findsOneWidget);
      expect(
        find.textContaining('when you choose a new chat PIN'),
        findsOneWidget,
      );
    });

    testWidgets('warns first when this device cannot keep the history', (
      tester,
    ) async {
      await open(tester, holdsKeys: false);

      expect(
        find.textContaining('earlier chat history can no longer be read'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePasswordPage), findsNothing);
    });
  });
}
