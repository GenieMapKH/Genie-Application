import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/presentation/create_account_page.dart';
import 'package:genie/shared/widgets/google_icon.dart';
import 'package:genie/core/services/auth_service.dart';
import 'package:dio/dio.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super(Dio());
  @override
  Future<void> register(String email, String password) async {}
}

void main() {
  final mockAuthService = MockAuthService();

  testWidgets('CreateAccountPage renders all form elements and links', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: const MaterialApp(home: CreateAccountPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Create an account'), findsOneWidget);

    // Verify Fields
    expect(find.byKey(const Key('name_field')), findsOneWidget);
    expect(find.byKey(const Key('identifier_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);

    // Verify Terms text
    expect(find.text('terms of services.'), findsOneWidget);

    // Verify Buttons
    expect(find.byKey(const Key('sign_up_button')), findsOneWidget);
    expect(find.byKey(const Key('google_button')), findsOneWidget);
    expect(find.byType(GoogleIcon), findsOneWidget);

    // Verify bottom link
    expect(find.text('Sign in here'), findsOneWidget);
  });

  testWidgets('CreateAccountPage validates inputs on submit', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: const MaterialApp(home: CreateAccountPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Sign up with empty fields
    final signUpButton = find.byKey(const Key('sign_up_button'));
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    // Verify errors
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(
      find.text('Enter a valid email address or phone number'),
      findsOneWidget,
    );
    expect(find.text('Enter a valid password'), findsOneWidget);
    expect(
      find.text('Please agree to the terms of services to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('CreateAccountPage triggers callbacks on valid submit', (
    WidgetTester tester,
  ) async {
    var signUpCalled = false;
    var googleCalled = false;
    var signInHereCalled = false;

    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: MaterialApp(
          home: CreateAccountPage(
            onSignUpPressed: () => signUpCalled = true,
            onGoogleSignUpPressed: () => googleCalled = true,
            onSignInHerePressed: () => signInHereCalled = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill valid info
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('name_field')),
        matching: find.byType(TextFormField),
      ),
      'John Doe',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('identifier_field')),
        matching: find.byType(TextFormField),
      ),
      'john@example.com',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byType(TextFormField),
      ),
      'password123',
    );

    // Agree to terms
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    // Scroll to bottom of terms
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    // Tap agree checkbox in terms modal
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();

    // Tap Sign up
    final signUpButton = find.byKey(const Key('sign_up_button'));
    debugPrint(tester.allWidgets.map((w) => w.toString()).join('\n'));
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();
    expect(signUpCalled, isTrue);

    // Tap Google button
    final googleButton = find.byKey(const Key('google_button'));
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();
    expect(googleCalled, isTrue);

    // Tap Sign in here link
    final signInHere = find.byKey(const Key('sign_in_here_link'));
    await tester.ensureVisible(signInHere);
    await tester.tap(signInHere);
    await tester.pumpAndSettle();
    expect(signInHereCalled, isTrue);
  });
}
