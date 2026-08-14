import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/auth/presentation/welcome_page.dart';
import 'package:genie/main.dart';
import 'package:genie/shared/widgets/app_button.dart';

void main() {
  testWidgets('MyApp renders WelcomePage with smooth splash and actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initially displays the WelcomePage
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Let splash delay and entrance animations complete
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify all interactive elements are visible and ready
    expect(find.byType(AppButton), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Explore without account'), findsOneWidget);
    expect(find.text('Create a Account'), findsOneWidget);
  });
}
