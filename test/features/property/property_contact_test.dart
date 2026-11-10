import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/data/repositories/user_repository.dart';
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
    'OAuth posting saves the first profile contact and never overwrites an existing one',
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
            ),
          ),
          userRepositoryProvider.overrideWithValue(UserRepository(server.dio)),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(
        addPropertyControllerProvider,
        (_, _) {},
      );
      addTearDown(keepAlive.close);
      final controller = container.read(addPropertyControllerProvider.notifier);
      await controller.ensureAccountPhone('012 345 678');
      expect(server.requests.single.method, 'PATCH');
      expect(server.requests.single.body, {'phone': '+85512345678'});
      await controller.ensureAccountPhone('098 765 432');
      expect(server.requests, hasLength(1));
      expect(phone, '+85512345678');
    },
  );
}
