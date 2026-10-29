import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/presentation/screens/welcome_page.dart';
import 'package:tilomnov/shared/widgets/buttons/app_button.dart';

void main() {
  testWidgets('MyApp renders WelcomePage with smooth splash and actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WelcomePage())),
    );
    await tester.pumpAndSettle();

    // Initially displays the WelcomePage
    expect(find.byType(WelcomePage), findsOneWidget);
    // The logo and the language switch's flag.
    expect(find.byType(SvgPicture), findsNWidgets(2));

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
