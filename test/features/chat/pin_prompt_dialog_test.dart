import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/e2ee/backup/pin_rules.dart';
import 'package:genie/features/chat/presentation/widgets/pin/pin_prompt_dialog.dart';

void main() {
  Future<Future<String?>> openPrompt(
    WidgetTester tester, {
    bool isNewPin = false,
  }) async {
    late Future<String?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => result = showPinPrompt(
              context,
              title: 'Create Backup PIN',
              helper: 'This PIN encrypts your chat keys.',
              isNewPin: isNewPin,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('a PIN shorter than 6 digits is not accepted', (tester) async {
    await openPrompt(tester);

    for (final weak in ['', '1', '12345', 'abcdef']) {
      await tester.enterText(find.byType(TextField), weak);
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Enter all 6 digits.'), findsOneWidget, reason: weak);
      expect(find.byType(AlertDialog), findsOneWidget, reason: weak);
    }
  });

  test('PINs an attacker would try first are recognised', () {
    for (final weak in ['000000', '777777', '123456', '654321', '012345']) {
      expect(isGuessablePin(weak), isTrue, reason: weak);
    }
    for (final weak in ['121212', '909090', '123123', '987987']) {
      expect(isGuessablePin(weak), isTrue, reason: weak);
    }
    for (final fine in ['482913', '135790', '112233', '102030']) {
      expect(isGuessablePin(fine), isFalse, reason: fine);
    }
  });

  testWidgets('a new PIN that is easy to guess is not accepted', (
    tester,
  ) async {
    await openPrompt(tester, isNewPin: true);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.text('Too easy to guess. Choose another PIN.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('an existing PIN is never refused for being simple', (
    tester,
  ) async {
    final result = await openPrompt(tester);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(await result, '123456');
  });

  testWidgets('a 6-digit PIN is returned', (tester) async {
    final result = await openPrompt(tester);

    await tester.enterText(find.byType(TextField), '482913');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(await result, '482913');
  });

  testWidgets('cancelling returns nothing', (tester) async {
    final result = await openPrompt(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
