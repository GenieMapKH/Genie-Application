import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_edit_route.dart';

void main() {
  const card = Rect.fromLTWH(16, 300, 328, 280);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              PropertyEditRoute(
                origin: card,
                page: const Scaffold(body: Text('edit form')),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
  }

  Rect window(WidgetTester tester) =>
      tester.getRect(find.byType(ClipRRect).first);

  testWidgets('the form grows out of the card to the whole screen', (
    tester,
  ) async {
    await open(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    final early = tester.getTopLeft(find.text('edit form'));
    expect(early.dy, greaterThan(100));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('edit form')).dy, lessThan(100));
    expect(
      window(tester).size,
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
  });

  testWidgets('closing shrinks the form back into the card', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(tester.getTopLeft(find.text('edit form')).dy, greaterThan(0));

    await tester.pumpAndSettle();
    expect(find.text('edit form'), findsNothing);
  });
}
