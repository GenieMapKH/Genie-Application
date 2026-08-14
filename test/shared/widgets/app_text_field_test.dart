import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/shared/widgets/app_text_field.dart';
import 'package:genie/shared/widgets/google_icon.dart';

void main() {
  testWidgets('AppTextField renders label, hint, and accepts user input',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            label: 'Email Address',
            hintText: 'example@gmail.com',
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('example@gmail.com'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    expect(controller.text, equals('test@example.com'));
  });

  testWidgets('AppTextField renders error message with info icon when errorText is provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTextField(
            label: 'Email Address',
            errorText: 'Enter a valid email address',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('GoogleIcon renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GoogleIcon(size: 24),
        ),
      ),
    );

    expect(find.byType(GoogleIcon), findsOneWidget);
  });
}
