import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/presentation/login_page.dart';
import 'package:genie/shared/widgets/app_button.dart';
import 'package:genie/shared/widgets/google_icon.dart';
import 'package:genie/core/services/auth_service.dart';
import 'package:dio/dio.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super(Dio());
  @override
  Future<void> login(String email, String password) async {}
}

void main() {
  final mockAuthService = MockAuthService();

  testWidgets('LoginPage renders all elements in Email mode by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Login'), findsNWidgets(2)); // Title + Button
    expect(find.text('Welcome back to the app'), findsOneWidget);

    // Verify Tabs
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);

    // Verify Email field is present by default
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsNothing);

    // Verify Password field
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.text('Forget Password?'), findsOneWidget);

    // Verify Checkbox
    expect(find.text('Keep me signed in'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);

    // Verify Google login button & icon
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(GoogleIcon), findsOneWidget);

    // Verify Create a Account link
    expect(find.text('Create a Account'), findsOneWidget);
  });

  testWidgets('LoginPage switches between Email and Phone Number tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Initial state: Email field visible
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsNothing);

    // Tap 'Phone Number' tab
    await tester.tap(find.text('Phone Number'));
    await tester.pumpAndSettle();

    // Phone field visible, Email field hidden
    expect(find.byKey(const Key('email_field')), findsNothing);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);

    // Tap 'Email' tab back
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsNothing);
  });

  testWidgets('LoginPage shows error state for invalid email and password', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Enter invalid email and invalid password
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('email_field')),
        matching: find.byType(TextFormField),
      ),
      'invalid-email',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byType(TextFormField),
      ),
      '123',
    );

    // Tap Login to trigger validation
    final primaryButtonFinder = find.widgetWithText(AppButton, 'Login');
    await tester.ensureVisible(primaryButtonFinder);
    await tester.tap(primaryButtonFinder);
    await tester.pumpAndSettle();

    // Verify error messages and info icons
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNWidgets(2));
  });

  testWidgets('LoginPage shows error state for invalid phone number', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Phone tab
    await tester.tap(find.text('Phone Number'));
    await tester.pumpAndSettle();

    // Enter invalid phone
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('phone_field')),
        matching: find.byType(TextFormField),
      ),
      '123',
    );

    // Tap Login
    final primaryButtonFinder = find.widgetWithText(AppButton, 'Login');
    await tester.ensureVisible(primaryButtonFinder);
    await tester.tap(primaryButtonFinder);
    await tester.pumpAndSettle();

    // Verify phone error message
    expect(find.text('Enter a valid phone number'), findsOneWidget);
  });

  testWidgets('LoginPage toggles password visibility', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();

    final visibilityIconButton = find.byType(IconButton);
    expect(visibilityIconButton, findsOneWidget);

    // Default: visibility icon shown
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    // Tap to reveal password
    await tester.tap(visibilityIconButton);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets(
    'LoginPage triggers login and google auth callbacks on valid input',
    (WidgetTester tester) async {
      var loginCalled = false;
      var googleCalled = false;

      // Set viewport size suitable for full mobile scroll
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(mockAuthService)],
          child: MaterialApp(
            home: LoginPage(
              onLoginPressed: () => loginCalled = true,
              onGoogleLoginPressed: () => googleCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill valid credentials
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('email_field')),
          matching: find.byType(TextFormField),
        ),
        'test@example.com',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('password_field')),
          matching: find.byType(TextFormField),
        ),
        'secret123',
      );

      // Tap Login button
      final primaryButtonFinder = find.widgetWithText(AppButton, 'Login');
      await tester.ensureVisible(primaryButtonFinder);
      await tester.tap(primaryButtonFinder);
      await tester.pumpAndSettle();
      expect(loginCalled, isTrue);

      // Tap Google button
      final googleButtonFinder = find.widgetWithText(
        AppButton,
        'Continue with Google',
      );
      await tester.ensureVisible(googleButtonFinder);
      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();
      expect(googleCalled, isTrue);
    },
  );
}
