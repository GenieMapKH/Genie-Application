import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/app/session/chat_pin_gate.dart';
import 'package:tilomnov/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:tilomnov/features/chat/e2ee/backup/password_lock_migration.dart';
import 'package:tilomnov/features/chat/e2ee/backup/pin_check.dart';
import 'package:tilomnov/features/chat/presentation/screens/chat_pin_setup_page.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';

import '../../support/test_app.dart';

/// Records the PINs created, and answers with [result].
class _FakeSetupService extends Fake implements E2eeSetupService {
  CreatePinResult result = CreatePinResult.created;
  final created = <String>[];

  @override
  Future<CreatePinResult> createPin(String userId, String pin) async {
    created.add(pin);
    return result;
  }
}

/// Only 'right-password' unlocks; records the PIN chats were moved to.
class _FakeMigration extends Fake implements PasswordLockMigration {
  final movedTo = <String>[];
  bool startedOver = false;

  @override
  Future<PinCheckResult> unlock(String password) async =>
      password == 'right-password'
      ? const PinAccepted()
      : const PinRejected(attemptsLeft: 4);

  @override
  Future<PinCheckResult> startOver(String password) async {
    startedOver = true;
    return const PinAccepted();
  }

  @override
  Future<PinCheckResult> moveToPin(String pin) async {
    movedTo.add(pin);
    return const PinAccepted();
  }
}

Override _signedIn() => userProfileProvider.overrideWith(
  (ref) async => UserProfile(id: 'u1', role: 'user', createdAt: DateTime(2026)),
);

void main() {
  late _FakeSetupService setup;
  late _FakeMigration migration;
  late int done;

  setUp(() {
    setup = _FakeSetupService();
    migration = _FakeMigration();
    done = 0;
  });

  Future<void> openSetup(WidgetTester tester, {bool fromPassword = false}) {
    return pumpTestApp(
      tester,
      ChatPinSetupPage(
        userId: 'u1',
        fromPassword: fromPassword,
        onDone: () => done++,
      ),
      overrides: [
        e2eeSetupServiceProvider.overrideWithValue(setup),
        passwordLockMigrationProvider.overrideWith((ref, _) => migration),
      ],
    );
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    await tester.enterText(find.byType(TextField), pin);
    await tester.pumpAndSettle();
  }

  group('creating the chat PIN', () {
    testWidgets('the PIN is typed twice, then saved', (tester) async {
      await openSetup(tester);
      expect(find.text('Create your chat PIN'), findsOneWidget);

      await typePin(tester, '482915');
      expect(find.text('Confirm your chat PIN'), findsOneWidget);
      expect(setup.created, isEmpty);

      await typePin(tester, '482915');

      expect(setup.created, ['482915']);
      expect(done, 1);
    });

    testWidgets('an easily guessed PIN is refused before anything is sent', (
      tester,
    ) async {
      await openSetup(tester);

      await typePin(tester, '123456');

      expect(
        find.text('Too easy to guess. Choose another PIN.'),
        findsOneWidget,
      );
      expect(find.text('Create your chat PIN'), findsOneWidget);
    });

    testWidgets('PINs that do not match start over', (tester) async {
      await openSetup(tester);

      await typePin(tester, '482915');
      await typePin(tester, '482916');

      expect(
        find.text('The PINs did not match. Choose your PIN again.'),
        findsOneWidget,
      );
      expect(find.text('Create your chat PIN'), findsOneWidget);
      expect(setup.created, isEmpty);
    });

    testWidgets('a PIN that could not be saved can be tried again', (
      tester,
    ) async {
      setup.result = CreatePinResult.failed;
      await openSetup(tester);

      await typePin(tester, '482915');
      await typePin(tester, '482915');

      expect(find.textContaining('Could not save your PIN'), findsOneWidget);
      expect(done, 0);

      setup.result = CreatePinResult.created;
      await typePin(tester, '482915');
      await typePin(tester, '482915');
      expect(done, 1);
    });

    testWidgets('a PIN set on another device meanwhile counts as done', (
      tester,
    ) async {
      setup.result = CreatePinResult.alreadySet;
      await openSetup(tester);

      await typePin(tester, '482915');
      await typePin(tester, '482915');

      expect(done, 1);
    });
  });

  group('chats still locked with the account password', () {
    testWidgets('the password comes first, then the new PIN', (tester) async {
      await openSetup(tester, fromPassword: true);
      expect(find.text('Protect your chats with a PIN'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'right-password');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Create your chat PIN'), findsOneWidget);
      await typePin(tester, '482915');
      await typePin(tester, '482915');

      expect(migration.movedTo, ['482915']);
      expect(setup.created, isEmpty);
      expect(done, 1);
    });

    testWidgets('a wrong password is said so, and starting over is offered', (
      tester,
    ) async {
      await openSetup(tester, fromPassword: true);
      expect(find.text("Can't unlock? Start over"), findsNothing);

      await tester.enterText(find.byType(TextField), 'typo');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('That is not your account password.'), findsOneWidget);
      await tester.tap(find.text("Can't unlock? Start over"));
      await tester.pumpAndSettle();
      // Losing the earlier messages is confirmed first.
      expect(find.text('Start over with new chat keys?'), findsOneWidget);
      await tester.tap(find.text('Start over'));
      await tester.pumpAndSettle();

      expect(migration.startedOver, isTrue);
      expect(find.text('Create your chat PIN'), findsOneWidget);
    });
  });

  group('the gate after signing in', () {
    Future<void> openApp(
      WidgetTester tester, {
      required ChatPinStatus? status,
      bool signedIn = true,
    }) async {
      await pumpTestApp(
        tester,
        const ChatPinGate(child: Text('the map')),
        overrides: [
          if (signedIn)
            _signedIn()
          else
            userProfileProvider.overrideWith((ref) async => null),
          chatPinStatusProvider.overrideWith((ref) async => status),
          e2eeSetupServiceProvider.overrideWithValue(setup),
          passwordLockMigrationProvider.overrideWith((ref, _) => migration),
        ],
      );
      await tester.pumpAndSettle();
    }

    testWidgets('an account without a PIN creates one before anything else', (
      tester,
    ) async {
      await openApp(tester, status: ChatPinStatus.notSet);

      expect(find.text('Create your chat PIN'), findsOneWidget);
      expect(find.text('the map'), findsNothing);
      // The way out for someone who does not want to go on.
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('chats locked with the password are moved to a PIN first', (
      tester,
    ) async {
      await openApp(tester, status: ChatPinStatus.lockedWithPassword);

      expect(find.text('Protect your chats with a PIN'), findsOneWidget);
      expect(find.text('the map'), findsNothing);
    });

    for (final status in [ChatPinStatus.set, ChatPinStatus.unknown]) {
      testWidgets('an account whose PIN is ${status.name} goes straight on', (
        tester,
      ) async {
        await openApp(tester, status: status);

        expect(find.text('the map'), findsOneWidget);
      });
    }

    testWidgets('a guest is never asked for a PIN', (tester) async {
      await openApp(tester, status: null, signedIn: false);

      expect(find.text('the map'), findsOneWidget);
    });
  });
}
