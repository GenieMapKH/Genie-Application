import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/presentation/screens/create_account_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/terms_of_service_page.dart';
import 'package:tilomnov/features/auth/presentation/view_models/sign_up_form.dart';
import 'package:tilomnov/shared/widgets/media/google_icon.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super(Dio());

  final calls = <Map<String, String?>>[];

  @override
  Future<void> register({
    required String phone,
    String? email,
    String? name,
    required String password,
  }) async {
    calls.add({
      'phone': phone,
      'email': email,
      'name': name,
      'password': password,
    });
  }
}

Finder _input(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(TextFormField),
);

void main() {
  late MockAuthService authService;

  setUp(() => authService = MockAuthService());

  Future<void> pumpPage(
    WidgetTester tester, {
    VoidCallback? onSignUp,
    VoidCallback? onGoogle,
    VoidCallback? onSignInHere,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(authService)],
        child: MaterialApp(
          home: CreateAccountPage(
            onSignUpPressed: onSignUp,
            onGoogleSignUpPressed: onGoogle,
            onSignInHerePressed: onSignInHere,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSignUp(WidgetTester tester) async {
    final button = find.byKey(const Key('sign_up_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('shows name, phone, optional email and password fields', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.byKey(const Key('name_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.text('Email (optional)'), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.text('terms of service'), findsOneWidget);
    expect(find.byKey(const Key('sign_up_button')), findsOneWidget);
    expect(find.byType(GoogleIcon), findsOneWidget);
    expect(find.text('Sign in here'), findsOneWidget);
  });

  testWidgets('requires name, phone, password and the terms; not an email', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapSignUp(tester);

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsNothing);
    expect(find.text('Enter a valid password'), findsOneWidget);
    expect(
      find.text('Please agree to the terms of services to continue.'),
      findsOneWidget,
    );
    expect(authService.calls, isEmpty);
  });

  testWidgets('refuses a typed email that is not one', (tester) async {
    await pumpPage(tester);

    await tester.enterText(_input('email_field'), 'not-an-email');
    await tapSignUp(tester);

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('ticking the box agrees at once, without opening the terms', (
    tester,
  ) async {
    await pumpPage(tester);

    bool ticked() => tester.widget<Checkbox>(find.byType(Checkbox)).value!;

    // The box itself, or the words next to it.
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(ticked(), isTrue);
    await tester.tap(find.text('I agree to the '));
    await tester.pumpAndSettle();
    expect(ticked(), isFalse);

    expect(find.byType(TermsOfServicePage), findsNothing);
  });

  testWidgets('the underlined words open the terms to read', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('terms_link')));
    await tester.pumpAndSettle();

    expect(find.byType(TermsOfServicePage), findsOneWidget);
  });

  testWidgets(
    'signs up with a phone only, sending it as the server stores it',
    (tester) async {
      var signedUp = false;
      var googleCalled = false;
      var signInHereCalled = false;
      await pumpPage(
        tester,
        onSignUp: () => signedUp = true,
        onGoogle: () => googleCalled = true,
        onSignInHere: () => signInHereCalled = true,
      );

      await tester.enterText(_input('name_field'), '  Sok Dara ');
      await tester.enterText(_input('phone_field'), '012 345 678');
      await tester.enterText(_input('password_field'), 'password123');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tapSignUp(tester);

      expect(signedUp, isTrue);
      expect(authService.calls.single, {
        'phone': '+85512345678',
        'email': null,
        'name': 'Sok Dara',
        'password': 'password123',
      });

      final googleButton = find.byKey(const Key('google_button'));
      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();
      expect(googleCalled, isTrue);

      final signInHere = find.byKey(const Key('sign_in_here_link'));
      await tester.ensureVisible(signInHere);
      await tester.tap(signInHere);
      await tester.pumpAndSettle();
      expect(signInHereCalled, isTrue);
    },
  );

  testWidgets('sends the email too when one is typed', (tester) async {
    await pumpPage(tester, onSignUp: () {});

    await tester.enterText(_input('name_field'), 'Dara');
    await tester.enterText(_input('phone_field'), '+855 97 123 4567');
    await tester.enterText(_input('email_field'), ' Dara@Gmail.com ');
    await tester.enterText(_input('password_field'), 'password123');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tapSignUp(tester);

    expect(authService.calls.single['phone'], '+855971234567');
    expect(authService.calls.single['email'], 'dara@gmail.com');
  });

  group('SignUpForm', () {
    SignUpForm form({String phone = '012345678', String email = ''}) =>
        SignUpForm(
          name: 'Dara',
          phone: phone,
          email: email,
          password: 'password123',
          agreedToTerms: true,
        );

    test('an empty email is fine and is not sent', () {
      expect(form().isValid, isTrue);
      expect(form(email: '   ').normalizedEmail, isNull);
    });

    test('refuses a phone number that is not one', () {
      for (final phone in ['', '123', 'john@example.com', "0' OR 1=1"]) {
        expect(form(phone: phone).phoneProblem, SignUpProblem.invalidPhone);
      }
    });
  });
}
