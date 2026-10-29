import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_nearby.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_sheet.dart';

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

  testWidgets('a listing opened from a card shows the full listing once read', (
    tester,
  ) async {
    final server = StubServer((request) => (200, '[]'));
    // What a feed card has: no counts (or boundary, description...).
    final card = PropertyModel(
      id: 'p-1',
      title: 'Near Ring Road 3',
      price: '100000',
      propertyType: 'Land',
      status: 'Active',
      createdAt: DateTime(2026),
      ownerId: 'owner',
    );
    final full = card.copyWith(viewCount: 7);

    await pumpTestApp(
      tester,
      PropertyDetailSheet(property: card),
      overrides: [
        propertyRepositoryProvider.overrideWithValue(
          PropertyRepository(server.dio),
        ),
        propertyDetailProvider.overrideWith((ref, id) async => full),
        userProfileProvider.overrideWith(
          (ref) async =>
              UserProfile(id: 'me', role: 'user', createdAt: DateTime(2026)),
        ),
        signedInOverride(),
      ],
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('7'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  });
}
