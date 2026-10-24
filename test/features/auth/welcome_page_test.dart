import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'package:genie/shared/widgets/buttons/app_button.dart';

void main() {
  testWidgets('WelcomePage renders logo, headlines, buttons, and link', (
    WidgetTester tester,
  ) async {
    var loginPressed = false;
    var explorePressed = false;
    var createAccountPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(
          splashDelay: Duration.zero,
          onLoginPressed: () => loginPressed = true,
          onExplorePressed: () => explorePressed = true,
          onCreateAccountPressed: () => createAccountPressed = true,
        ),
      ),
    );

    // Let entrance animations complete
    await tester.pumpAndSettle();

    // Verify logo
    final logoFinder = find.byWidgetPredicate(
      (widget) => widget is SvgPicture && widget.width == 220.0,
    );
    expect(logoFinder, findsOneWidget);
    final logo = tester.widget<SvgPicture>(logoFinder);
    expect(logo.width, equals(220.0));
    expect(logo.height, equals(150.0));

    // Verify headline and subtitle
    expect(find.text('Welcome to the app'), findsOneWidget);
    expect(
      find.text('Find and share properties with exact map location'),
      findsOneWidget,
    );

    // Verify buttons
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Explore without account'), findsOneWidget);
    expect(find.byType(AppButton), findsNWidgets(2));

    // Verify link
    expect(find.text('Create a Account'), findsOneWidget);

    // Verify interactions
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(loginPressed, isTrue);

    await tester.tap(find.text('Explore without account'));
    await tester.pumpAndSettle();
    expect(explorePressed, isTrue);

    await tester.tap(find.text('Create a Account'));
    await tester.pumpAndSettle();
    expect(createAccountPressed, isTrue);
  });
}
