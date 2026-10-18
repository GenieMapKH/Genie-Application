import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/data/repositories/property_repository.dart';
import 'package:genie/features/property/presentation/view_models/property_providers.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_detail_sheet.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('opening a listing counts the viewer without a build error', (
    tester,
  ) async {
    final server = StubServer((request) => (200, '[]'));
    final property = PropertyModel(
      id: 'p-1',
      title: 'Near Ring Road 3',
      price: '100000',
      propertyType: 'Land',
      status: 'Active',
      createdAt: DateTime(2026),
      ownerId: 'owner',
    );

    await pumpTestApp(
      tester,
      PropertyDetailSheet(property: property),
      overrides: [
        propertyRepositoryProvider.overrideWithValue(
          PropertyRepository(server.dio),
        ),
        userProfileProvider.overrideWith(
          (ref) async =>
              UserProfile(id: 'me', role: 'user', createdAt: DateTime(2026)),
        ),
        signedInOverride(),
      ],
    );
    await tester.pump(const Duration(milliseconds: 200));

    // A provider changed while the tree was building would have thrown.
    expect(tester.takeException(), isNull);
    expect(
      server.requests.where((r) => r.path.endsWith('/properties/p-1/view')),
      hasLength(1),
    );

    // Lets the stubbed requests' timers finish before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
