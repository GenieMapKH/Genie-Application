import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';
import 'package:genie/features/chat/presentation/widgets/pin/pin_check_dialog.dart';
import 'package:genie/features/chat/presentation/widgets/pin/pin_status_line.dart';

import '../../support/test_app.dart';

void main() {
  /// Opens the dialog; each PIN typed is answered with the next of
  /// [answers]. Returns what the dialog ended with, and the PINs checked.
  Future<({Future<bool> closed, List<String> checked})> open(
    WidgetTester tester,
    List<PinCheckResult> answers,
  ) async {
    late Future<bool> closed;
    final checked = <String>[];
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => closed = showPinCheckDialog(
              context,
              title: 'Enter your chat PIN',
              helper: 'Enter it to read your chats on this phone.',
              check: (pin) async {
                checked.add(pin);
                return answers.removeAt(0);
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (closed: closed, checked: checked);
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    await tester.enterText(find.byType(TextField), pin);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a wrong PIN is explained in the dialog, which stays open', (
    tester,
  ) async {
    final dialog = await open(tester, [
      const PinRejected(attemptsLeft: 3),
      const PinAccepted(),
    ]);

    // The sixth digit checks the PIN; no button needed.
    await typePin(tester, '000000');

    expect(find.text('Incorrect PIN. 3 tries left.'), findsOneWidget);
    expect(find.text('Enter your chat PIN'), findsOneWidget);
    // Typed again from the start.
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');

    await typePin(tester, '482915');
    await tester.pumpAndSettle();

    expect(dialog.checked, ['000000', '482915']);
    expect(await dialog.closed, isTrue);
    expect(find.text('Enter your chat PIN'), findsNothing);
  });

  testWidgets('the last try before the lock is called out', (tester) async {
    await open(tester, [const PinRejected(attemptsLeft: 1)]);

    await typePin(tester, '000000');

    expect(find.textContaining('1 try left before your PIN locks'), findsOneWidget);
  });

  testWidgets('after too many wrong PINs it counts down, then lets the user '
      'try again', (tester) async {
    await open(tester, [
      const PinLockedOut(retryAfter: Duration(minutes: 15)),
      const PinAccepted(),
    ]);

    await typePin(tester, '000000');

    expect(find.text('Too many wrong PINs. Try again in 15:00.'), findsOneWidget);
    expect(find.byIcon(Icons.lock_clock_outlined), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    await tester.pump(const Duration(minutes: 1));
    expect(find.text('Too many wrong PINs. Try again in 14:00.'), findsOneWidget);

    await tester.pump(const Duration(minutes: 15));
    expect(find.textContaining('Too many wrong PINs'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('a lock of unknown length says to come back later', (
    tester,
  ) async {
    await open(tester, [const PinLockedOut()]);

    await typePin(tester, '000000');

    expect(
      find.text('Too many wrong PINs. Please try again later.'),
      findsOneWidget,
    );
  });

  testWidgets('no connection keeps the PIN, to try again as it is', (
    tester,
  ) async {
    final dialog = await open(tester, [
      const PinCheckFailed(),
      const PinAccepted(),
    ]);

    await typePin(tester, '482915');

    expect(find.textContaining('Could not check your PIN'), findsOneWidget);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(dialog.checked, ['482915', '482915']);
    expect(await dialog.closed, isTrue);
  });

  testWidgets('closing the dialog gives up', (tester) async {
    final dialog = await open(tester, []);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await dialog.closed, isFalse);
    expect(dialog.checked, isEmpty);
  });

  test('a wait is shown as minutes and seconds, or hours for long ones', () {
    expect(formatWait(const Duration(minutes: 15)), '15:00');
    expect(formatWait(const Duration(seconds: 9)), '0:09');
    expect(formatWait(const Duration(hours: 2, minutes: 3, seconds: 4)), '2:03:04');
  });
}
