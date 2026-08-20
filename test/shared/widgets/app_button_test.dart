import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/shared/widgets/app_button.dart';

void main() {
  testWidgets('AppButton.primary renders with text and triggers callback', (
    WidgetTester tester,
  ) async {
    var wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.primary(
            text: 'Login',
            onPressed: () {
              wasPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Login'), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints?.maxWidth, equals(408.0));

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(wasPressed, isTrue);
  });

  testWidgets('AppButton.secondary renders with correct border and text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton.secondary(
            text: 'Explore without account',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Explore without account'), findsOneWidget);
  });

  testWidgets('AppButton displays loading indicator when isLoading is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(text: 'Submit', onPressed: () {}, isLoading: true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
  });
}
