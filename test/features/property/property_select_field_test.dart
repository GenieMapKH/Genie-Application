import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/features/property/presentation/widgets/forms/fields/property_select_field.dart';

const _fieldKey = Key('field');

Future<List<String?>> _pump(
  WidgetTester tester, {
  String? value = 'Rent',
}) async {
  final picked = <String?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 180,
              child: PropertySelectField(
                key: _fieldKey,
                value: value,
                items: const ['Sale', 'Rent', 'To Let'],
                labelOf: (item) => item,
                decoration: const InputDecoration(hintText: 'Select'),
                onChanged: picked.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return picked;
}

void main() {
  testWidgets('opens under the field, as wide, leaving the value readable', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();

    final field = tester.getRect(find.byKey(_fieldKey));
    final menu = tester.getRect(find.byType(ListView));
    expect(menu.top, greaterThanOrEqualTo(field.bottom));
    expect(menu.width, field.width);
    // The picked value shows in the field and, ticked, in the list.
    expect(find.text('Rent'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('picking an option reports it and closes the list', (
    tester,
  ) async {
    final picked = await _pump(tester);
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To Let'));
    await tester.pumpAndSettle();

    expect(picked, ['To Let']);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('a tap outside closes the list without picking', (tester) async {
    final picked = await _pump(tester);
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 500));
    await tester.pumpAndSettle();

    expect(picked, isEmpty);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('a value the list does not offer shows the hint', (tester) async {
    await _pump(tester, value: 'Lease');
    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Lease'), findsNothing);
  });
}
