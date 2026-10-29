import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/auth/presentation/screens/terms_of_service_page.dart';

void main() {
  testWidgets('TermsOfServicePage can be agreed to without scrolling', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Terms of Service for Tilomnov'), findsOneWidget);
    expect(find.text('1. About Tilomnov'), findsOneWidget);
    expect(find.text('2. User Accounts'), findsOneWidget);

    // Not scrolled at all: ticking still agrees, and returns to the form.
    await tester.tap(find.byKey(const Key('terms_agree_row')));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(find.byType(TermsOfServicePage), findsNothing);
  });
}
