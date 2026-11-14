import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/security/data/repositories/account_repository.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';
import 'package:tilomnov/features/auth/data/phone_verification_service.dart';
import '../auth/phone_verification_fakes.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page_logic.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/add_property_controller.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_form_input.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'account contact prefills and the plus button adds another phone field',
    (tester) async {
      await pumpTestApp(
        tester,
        const AddPropertyPage(boundaryPoints: [], propertyArea: 100),
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'owner',
              role: 'user',
              createdAt: DateTime(2026),
              phone: '+85512345678',
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      final state = tester.state<AddPropertyPageState>(
        find.byType(AddPropertyPage),
      );
      expect(state.phoneController.text, '+85512345678');
      await tester.scrollUntilVisible(
        find.byTooltip('Add another phone number'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Add another phone number'));
      await tester.pumpAndSettle();
      expect(state.additionalPhoneControllers, hasLength(1));
      state.additionalPhoneControllers.single.text = '098 765 432';
      final body = PropertyFormInput(
        contactPhone: state.phoneController.text,
        additionalContactPhones: [state.additionalPhoneControllers.single.text],
      ).toRequestBody();
      expect(body['contactPhone'], '+85512345678');
      expect(body['additionalContactPhones'], ['+85598765432']);
    },
  );

  test(
    'optional OAuth phone verification saves a verified first account phone',
    () async {
      String? phone;
      final server = StubServer((request) {
        phone = (request.data as Map)['phone'] as String;
        return (
          200,
          '{"id":"owner","role":"user","phone":"+85512345678","createdAt":"2026-01-01T00:00:00Z"}',
        );
      });
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'owner',
              role: 'user',
              createdAt: DateTime(2026),
              phone: phone,
              phoneVerified: phone != null,
            ),
          ),
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(server.dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(
        addPropertyControllerProvider,
        (_, _) {},
      );
      addTearDown(keepAlive.close);
      final controller = container.read(addPropertyControllerProvider.notifier);
      await expectLater(
        controller.ensureAccountPhone('012 345 678'),
        throwsStateError,
      );
      expect(server.requests, isEmpty);
      await controller.ensureAccountPhone(
        '012 345 678',
        phoneProof: 'sms-proof',
      );
      expect(server.requests.single.method, 'POST');
      expect(server.requests.single.path, '/auth/account/phone/verify');
      expect(server.requests.single.body, {
        'phone': '+85512345678',
        'phoneProof': 'sms-proof',
      });
      await controller.ensureAccountPhone('098 765 432');
      expect(server.requests, hasLength(1));
      expect(phone, '+85512345678');
    },
  );
  testWidgets('OAuth user verifies from the bottom contact section', (
    tester,
  ) async {
    final sms = FakePhoneVerification();
    var verified = false;
    final server = StubServer((request) {
      verified = true;
      return (200, '{}');
    });
    await pumpTestApp(
      tester,
      const AddPropertyPage(boundaryPoints: [], propertyArea: 100),
      overrides: [
        phoneVerificationServiceProvider.overrideWithValue(sms),
        accountRepositoryProvider.overrideWithValue(
          AccountRepository(server.dio),
        ),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'owner',
            role: 'user',
            createdAt: DateTime(2026),
            phone: verified ? '+85512345678' : null,
            phoneVerified: verified,
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();
    final state = tester.state<AddPropertyPageState>(
      find.byType(AddPropertyPage),
    );
    state.phoneController.text = '012 345 678';
    await tester.scrollUntilVisible(
      find.byKey(const Key('property_verify_phone')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('property_verify_phone')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(server.requests, isEmpty);
    expect(sms.challenges.single.phone, '+85512345678');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('contact_otp')),
        matching: find.byType(TextFormField),
      ),
      '123456',
    );
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(server.requests.single.path, '/auth/account/phone/verify');
    expect(server.requests.single.body, {
      'phone': '+85512345678',
      'phoneProof': 'phone-proof',
    });
    expect(find.text('Account phone verified'), findsOneWidget);
    expect(await state.verifyContactPhone(), isTrue);
    expect(sms.challenges, hasLength(1));
  });

  testWidgets(
    'cancelling property SMS verification leaves the phone unverified',
    (tester) async {
      final sms = FakePhoneVerification();
      final server = StubServer.always(200);
      await pumpTestApp(
        tester,
        const AddPropertyPage(boundaryPoints: [], propertyArea: 100),
        overrides: [
          phoneVerificationServiceProvider.overrideWithValue(sms),
          accountRepositoryProvider.overrideWithValue(
            AccountRepository(server.dio),
          ),
          userProfileProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'owner',
              role: 'user',
              createdAt: DateTime(2026),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      final state = tester.state<AddPropertyPageState>(
        find.byType(AddPropertyPage),
      );
      state.phoneController.text = '012345678';
      final attempt = state.verifyContactPhone();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await attempt, isFalse);
      expect(server.requests, isEmpty);
      expect(sms.challenges.single.closed, isTrue);
    },
  );
}
