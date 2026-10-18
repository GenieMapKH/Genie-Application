import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/presentation/screens/login_page.dart';
import 'package:genie/shared/widgets/buttons/app_button.dart';
import 'package:genie/shared/widgets/media/google_icon.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:genie/features/auth/data/google_sign_in_service.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'package:genie/features/auth/presentation/view_models/login_controller.dart';
import 'package:genie/features/auth/presentation/widgets/sign_in_required_dialog.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_app.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super(Dio());
  @override
  Future<void> login(String email, String password) async {}
}

/// Google sign-in that succeeds after a moment, as the real one does.
class _GoogleSignsIn extends LoginController {
  int signIns = 0;

  _GoogleSignsIn() : super(MockAuthService(), GoogleSignInService());

  @override
  Future<bool> googleLogin({bool forceAccountSelection = false}) async {
    signIns++;
    state = const AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = const AsyncData(true);
    return true;
  }
}

/// The app's routes, with the map replaced by a button that needs an account.
GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const WelcomePage()),
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(
      path: '/home',
      builder: (_, _) => Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSignInRequiredDialog(context),
            child: const Text('map'),
          ),
        ),
      ),
    ),
  ],
);

Future<void> _tapGoogle(WidgetTester tester) async {
  final google = find.widgetWithText(AppButton, 'Continue with Google');
  await tester.ensureVisible(google);
  await tester.tap(google);
  await tester.pumpAndSettle();
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

  group('signing in with Google', () {
    late _GoogleSignsIn login;

    Future<GoRouter> pump(WidgetTester tester, String location) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      login = _GoogleSignsIn();
      final router = _router(location);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            loginControllerProvider.overrideWith((ref) => login),
            signedInOverride(signedIn: false),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('says so once and goes to the map', (tester) async {
      await pump(tester, '/login');

      await _tapGoogle(tester);

      expect(login.signIns, 1);
      expect(find.text('Successfully logged in!'), findsOneWidget);
      expect(find.text('map'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      // Toasts leave after a few seconds.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'from "Account required" it goes to the map, not back to welcome',
      (tester) async {
        await pump(tester, '/home');

        await tester.tap(find.text('map'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Login / Sign Up'));
        await tester.pumpAndSettle();
        expect(find.byType(WelcomePage), findsOneWidget);

        await tester.tap(find.widgetWithText(AppButton, 'Login'));
        await tester.pumpAndSettle();
        await _tapGoogle(tester);

        expect(find.byType(WelcomePage), findsNothing);
        expect(find.byType(LoginPage), findsNothing);
        expect(find.text('map'), findsOneWidget);
        expect(find.text('Successfully logged in!'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      },
    );
  });
}
