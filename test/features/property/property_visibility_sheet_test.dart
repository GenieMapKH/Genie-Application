import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_visibility.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/actions/property_visibility_sheet.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('waits for confirmation and prevents duplicate requests', (
    tester,
  ) async {
    final gate = Completer<void>();
    var calls = 0;
    PropertyVisibility? saved;
    await pumpTestApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await PropertyVisibilitySheet.show(
                context,
                'Draft',
                onChanged: (_) {
                  calls++;
                  return gate.future;
                },
              );
            },
            child: const Text('Visibility'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Visibility'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Public'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(saved, isNull);
    expect(
      tester.widget<ListTile>(find.byType(ListTile).first).enabled,
      isFalse,
    );
    await tester.tap(find.text('Public'));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.drag(
      find.byType(PropertyVisibilitySheet),
      const Offset(0, 400),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 1);
    expect(find.byType(PropertyVisibilitySheet), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(saved, PropertyVisibility.public);
    expect(find.byType(PropertyVisibilitySheet), findsNothing);
  });

  testWidgets('a refused change stays open with an error and can be retried', (
    tester,
  ) async {
    var calls = 0;
    await pumpTestApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => PropertyVisibilitySheet.show(
              context,
              'Draft',
              onChanged: (_) async {
                calls++;
                if (calls == 1) throw Exception('refused');
              },
            ),
            child: const Text('Visibility'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Visibility'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Public'));
    await tester.pumpAndSettle();

    expect(find.byType(PropertyVisibilitySheet), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text('Could not change the visibility. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<ListTile>(find.byType(ListTile).first).enabled,
      isTrue,
    );

    await tester.tap(find.text('Public'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(PropertyVisibilitySheet), findsNothing);
  });
}
