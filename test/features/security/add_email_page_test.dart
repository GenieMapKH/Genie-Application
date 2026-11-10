import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/screens/personal_info_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/security/data/repositories/account_repository.dart';
import 'package:tilomnov/features/security/presentation/screens/add_email_page.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';
import 'package:tilomnov/shared/widgets/buttons/app_button.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import '../../support/test_app.dart';

class _EmailCodes extends AuthService {
  _EmailCodes() : super(Dio());
  @override
  Future<void> requestEmailVerification(String email) async {}
  @override
  Future<String> confirmEmailVerification(String email, String otp) async =>
      'email-proof';
}

UserProfile _profile({String? email}) => UserProfile(
  id: 'u1',
  email: email,
  emailVerified: email != null,
  phone: '+85512345678',
  username: 'dara',
  role: 'user',
  createdAt: DateTime(2026),
);

Finder _input(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(TextFormField),
);

void main() {
  testWidgets('a phone-only account adds an email from personal info', (
    tester,
  ) async {
    final server = StubServer.always(200);
    await pumpTestApp(
      tester,
      const PersonalInfoPage(),
      overrides: [
        authServiceProvider.overrideWithValue(_EmailCodes()),
        userProfileProvider.overrideWith((ref) async => _profile()),
        accountRepositoryProvider.overrideWithValue(
          AccountRepository(server.dio),
        ),
      ],
    );

    await tester.tap(find.text('Add email'));
    await tester.pumpAndSettle();
    expect(find.byType(AddEmailPage), findsOneWidget);

    await tester.enterText(_input('add_email_field'), 'dara@example.com');
    await tester.enterText(_input('add_email_password_field'), 'secret');
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(server.requests, isEmpty);
    await tester.enterText(_input('contact_otp'), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(server.requests.single.path, '/auth/account/email');
    expect(server.requests.single.body, {
      'email': 'dara@example.com',
      'password': 'secret',
      'emailProof': 'email-proof',
    });
    expect(find.byType(AddEmailPage), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('an account that has an email cannot replace it from here', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const PersonalInfoPage(),
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => _profile(email: 'dara@example.com'),
        ),
      ],
    );

    await tester.tap(find.text('dara@example.com'));
    await tester.pumpAndSettle();

    expect(find.byType(AddEmailPage), findsNothing);
  });

  testWidgets('says when another account has the email', (tester) async {
    await pumpTestApp(
      tester,
      const AddEmailPage(),
      overrides: [
        authServiceProvider.overrideWithValue(_EmailCodes()),
        accountRepositoryProvider.overrideWithValue(
          AccountRepository(StubServer.always(409).dio),
        ),
      ],
    );

    await tester.enterText(_input('add_email_field'), 'taken@example.com');
    await tester.enterText(_input('add_email_password_field'), 'secret');
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(_input('contact_otp'), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(
      find.text('This email is already used by another account.'),
      findsOneWidget,
    );
  });

  testWidgets('checks the email before asking the server', (tester) async {
    final server = StubServer.always(200);
    await pumpTestApp(
      tester,
      const AddEmailPage(),
      overrides: [
        accountRepositoryProvider.overrideWithValue(
          AccountRepository(server.dio),
        ),
      ],
    );

    await tester.enterText(_input('add_email_field'), 'not-an-email');
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter your current password.'), findsOneWidget);
    expect(server.requests, isEmpty);
  });
}
