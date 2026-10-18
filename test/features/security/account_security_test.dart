import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/security/data/models/device_session.dart';
import 'package:genie/features/security/data/repositories/account_repository.dart';
import 'package:genie/features/security/data/repositories/session_repository.dart';
import 'package:genie/features/security/presentation/view_models/account_security_controller.dart';
import 'package:genie/features/security/presentation/widgets/device_session_tile.dart';
import 'package:genie/l10n/l10n.dart';

import '../../support/test_app.dart';

const _sessionsJson =
    '{"sessions":[{"id":"s1","deviceName":"Pixel 8","platform":"Android 15",'
    '"ipAddress":"203.0.113.7","location":"Phnom Penh, Cambodia",'
    '"signedInAt":"2026-03-01T08:00:00.000Z","lastUsedAt":"2026-03-02T08:00:00.000Z",'
    '"current":true},'
    '{"id":"s2","deviceName":null,"platform":null,"ipAddress":null,"location":null,'
    '"signedInAt":"2026-02-01T08:00:00.000Z","lastUsedAt":"2026-02-20T08:00:00.000Z",'
    '"current":false}],'
    '"canSignOutOthers":false,"canSignOutOthersFrom":"2026-03-02T08:00:00.000Z"}';

void main() {
  group('AccountSecurityController.checkNewPassword', () {
    PasswordProblem? check({
      String current = 'old-password',
      String next = 'new-password',
      String? confirmation,
    }) => AccountSecurityController.checkNewPassword(
      current: current,
      next: next,
      confirmation: confirmation ?? next,
    );

    test('accepts a new password typed twice', () {
      expect(check(), isNull);
    });

    test('names the first thing that is wrong', () {
      expect(check(current: ''), PasswordProblem.currentMissing);
      expect(check(next: 'short'), PasswordProblem.tooShort);
      expect(check(confirmation: 'different'), PasswordProblem.mismatch);
      expect(check(next: 'old-password'), PasswordProblem.sameAsCurrent);
    });
  });

  group('AccountSecurityController', () {
    AccountSecurityController controllerAnswering(int status) =>
        AccountSecurityController(
          AccountRepository(StubServer.always(status).dio),
        );

    test('changing the password sends both passwords', () async {
      final server = StubServer.always(200);
      final controller = AccountSecurityController(
        AccountRepository(server.dio),
      );

      final result = await controller.changePassword(
        current: 'old-password',
        next: 'new-password',
      );

      expect(result, AccountActionResult.done);
      final request = server.requests.single;
      expect((request.method, request.path), ('POST', '/auth/change-password'));
      expect(request.body, {
        'currentPassword': 'old-password',
        'newPassword': 'new-password',
      });
    });

    test('changing the password keeps the chat keys locked with it', () async {
      final locked = <String>[];
      final controller = AccountSecurityController(
        AccountRepository(StubServer.always(200).dio),
        lockChatKeys: (password) async => locked.add(password),
      );

      await controller.changePassword(
        current: 'old-password',
        next: 'new-password',
      );

      // Made sure to be here first, then locked with the new one.
      expect(locked, ['old-password', 'new-password']);
    });

    test('a refused password change leaves the chat keys alone', () async {
      final locked = <String>[];
      final controller = AccountSecurityController(
        AccountRepository(StubServer.always(403).dio),
        lockChatKeys: (password) async => locked.add(password),
      );

      await controller.changePassword(
        current: 'old-password',
        next: 'new-password',
      );

      expect(locked, ['old-password']);
    });

    test('a first password protects the chats from then on', () async {
      final locked = <String>[];
      final controller = AccountSecurityController(
        AccountRepository(StubServer.always(200).dio),
        lockChatKeys: (password) async => locked.add(password),
      );

      await controller.createPassword(
        googleIdToken: 'google-token',
        password: 'first-password',
      );

      expect(locked, ['first-password']);
    });

    test('deactivating proves identity with the password', () async {
      final server = StubServer.always(200);
      final controller = AccountSecurityController(
        AccountRepository(server.dio),
      );

      await controller.deactivate(const IdentityProof.password('secret'));

      expect(server.requests.single.path, '/auth/account/deactivate');
      expect(server.requests.single.body, {'password': 'secret'});
    });

    test('deleting can prove identity with a fresh Google sign-in', () async {
      final server = StubServer.always(200);
      final controller = AccountSecurityController(
        AccountRepository(server.dio),
      );

      await controller.delete(const IdentityProof.google('id-token'));

      expect(server.requests.single.path, '/auth/account/delete');
      expect(server.requests.single.body, {'idToken': 'id-token'});
    });

    test('tells a wrong password from a lockout and a failure', () async {
      const proof = IdentityProof.password('guess');

      expect(
        await controllerAnswering(403).delete(proof),
        AccountActionResult.identityRejected,
      );
      expect(
        await controllerAnswering(429).deactivate(proof),
        AccountActionResult.tooManyAttempts,
      );
      expect(
        await controllerAnswering(500).delete(proof),
        AccountActionResult.failed,
      );
    });
  });

  group('SessionRepository', () {
    test('reads the device list', () async {
      final devices = await SessionRepository(
        StubServer.always(200, _sessionsJson).dio,
      ).fetchSessions();
      final sessions = devices.sessions;

      // A device that signed in less than a day ago may not remove the others yet.
      expect(devices.canSignOutOthers, isFalse);
      expect(devices.canSignOutOthersFrom, DateTime.utc(2026, 3, 2, 8));
      expect(devices.others.single.id, 's2');
      expect(sessions, hasLength(2));
      expect(sessions.first.deviceName, 'Pixel 8');
      expect(sessions.first.location, 'Phnom Penh, Cambodia');
      expect(sessions.first.isCurrent, isTrue);
      expect(sessions.first.lastUsedAt, DateTime.utc(2026, 3, 2, 8));
      expect(sessions.last.deviceName, isNull);
      expect(sessions.last.isCurrent, isFalse);
    });

    test('signs out one device, or all of them', () async {
      final server = StubServer.always(200);
      final repository = SessionRepository(server.dio);

      await repository.signOut('s2');
      await repository.signOutAll();

      expect(
        [for (final request in server.requests) (request.method, request.path)],
        [('DELETE', '/auth/sessions/s2'), ('POST', '/auth/logout-all')],
      );
    });
  });

  group('lastUsedLabel', () {
    final l10n = lookupAppLocalizations(AppLanguages.english);
    final now = DateTime.utc(2026, 3, 10, 12);

    DeviceSession usedAgo(Duration ago, {bool isCurrent = false}) =>
        DeviceSession(
          id: 's',
          signedInAt: now.subtract(const Duration(days: 30)),
          lastUsedAt: now.subtract(ago),
          isCurrent: isCurrent,
        );

    test('counts in the largest unit that fits', () {
      String label(Duration ago) => lastUsedLabel(l10n, usedAgo(ago), now);

      expect(label(const Duration(seconds: 30)), 'Active now');
      expect(label(const Duration(minutes: 1)), 'Last used 1 minute ago');
      expect(label(const Duration(minutes: 59)), 'Last used 59 minutes ago');
      expect(label(const Duration(hours: 5)), 'Last used 5 hours ago');
      expect(label(const Duration(days: 1)), 'Last used yesterday');
      expect(label(const Duration(days: 12)), 'Last used 12 days ago');
    });

    test('the device that is looking is always active', () {
      final current = usedAgo(const Duration(minutes: 14), isCurrent: true);

      expect(lastUsedLabel(l10n, current, now), 'Active now');
    });

    test('is translated', () {
      final khmer = lookupAppLocalizations(AppLanguages.khmer);

      expect(
        lastUsedLabel(khmer, usedAgo(const Duration(hours: 5)), now),
        'ប្រើចុងក្រោយ 5 ម៉ោងមុន',
      );
    });
  });
}
