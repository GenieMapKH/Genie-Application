import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/presentation/widgets/delete_chat_dialog.dart';

import '../../support/test_app.dart';

void main() {
  /// Opens the dialog, lets [act] answer it, and returns its answer.
  Future<bool?> answer(
    WidgetTester tester,
    Future<void> Function() act,
  ) async {
    bool? result;
    var closed = false;
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await DeleteChatDialog.show(context, 'Sokha');
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await act();
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    return result;
  }

  testWidgets('deletes for me only unless the box is ticked', (tester) async {
    final forEveryone = await answer(
      tester,
      () => tester.tap(find.text('Delete')),
    );

    expect(forEveryone, isFalse);
  });

  testWidgets('ticking the box deletes it for both people, with a warning', (
    tester,
  ) async {
    final forEveryone = await answer(tester, () async {
      expect(find.textContaining('Sokha still has it'), findsOneWidget);
      await tester.tap(find.text('Also delete for Sokha'));
      await tester.pump();
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      await tester.tap(find.text('Delete'));
    });

    expect(forEveryone, isTrue);
  });

  testWidgets('cancelling deletes nothing', (tester) async {
    final forEveryone = await answer(
      tester,
      () => tester.tap(find.text('Cancel')),
    );

    expect(forEveryone, isNull);
  });
}
