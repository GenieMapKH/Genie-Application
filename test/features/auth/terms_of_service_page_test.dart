import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/auth/presentation/screens/terms_of_service_page.dart';

void main() {
  testWidgets('TermsOfServicePage renders sections and enforces scroll to bottom', (
    WidgetTester tester,
  ) async {
    var agreed = false;

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: TermsOfServicePage(onAgreeChanged: (val) => agreed = val),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and headers
    expect(find.text('Terms of Service for Genie Property'), findsOneWidget);
    expect(find.text('1. About Genie'), findsOneWidget);
    expect(find.text('2. User Accounts'), findsOneWidget);
    expect(find.text('3. Property Listings'), findsOneWidget);

    // Initial state: not scrolled to bottom, agreement text shows scroll instruction
    expect(
      find.text('Scroll to bottom to agree terms of services'),
      findsOneWidget,
    );

    // Tap agree before scrolling -> remains false
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(agreed, isFalse);

    // Scroll to the bottom
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('4. Map and Coordinate Accuracy'),
      500.0,
      scrollable: scrollable,
    );
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Now scrolled to bottom -> instruction changes to 'Agree terms of services'
    expect(find.text('Agree terms of services'), findsOneWidget);

    // Tap checkbox to agree
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(agreed, isTrue);
  });
}
