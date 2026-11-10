import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/data/repositories/user_repository.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/profile/presentation/widgets/profile_field_editor.dart';
import 'package:tilomnov/features/security/data/repositories/account_repository.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('changing a contact phone requires identity and sends no SMS', (
    tester,
  ) async {
    final server = StubServer.always(200);
    await pumpTestApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showProfileFieldEditor(
              context,
              field: ProfileField.phone,
              label: 'Phone',
              invalidMessage: 'Invalid phone',
              initialValue: '+85512345678',
            ),
            child: const Text('Edit phone'),
          ),
        ),
      ),
      overrides: [
        accountRepositoryProvider.overrideWithValue(
          AccountRepository(server.dio),
        ),
        userProfileProvider.overrideWith(
          (ref) async =>
              UserProfile(id: 'u1', role: 'user', createdAt: DateTime(2026)),
        ),
      ],
    );
    await tester.tap(find.text('Edit phone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+85598765432');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(server.requests, isEmpty);

    await tester.enterText(find.byType(TextField).last, 'current-password');
    await tester.tap(find.text('Verify'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(server.requests.single.path, '/auth/account/phone');
    expect(server.requests.single.body, {
      'password': 'current-password',
      'phone': '+85598765432',
    });
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
