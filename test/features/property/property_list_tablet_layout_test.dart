import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/property_list_layout.dart';
import 'package:tilomnov/features/property/presentation/screens/my_properties_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_card.dart';

import '../../support/test_app.dart';

/// Serves a fixed set of the user's listings in one page.
class _Server extends PropertyRepository {
  final List<PropertyModel> listings;

  _Server(int count)
    : listings = [
        for (var i = 0; i < count; i++)
          PropertyModel.fromJson({
            'id': 'p$i',
            'title': 'p$i',
            'price': '1',
            'propertyType': 'House',
            'status': 'Active',
            'createdAt': '2026-10-01T00:00:00.000Z',
          }),
      ],
      super(Dio());

  @override
  Future<OwnListingsPage> fetchOwnPage({
    required int offset,
    int limit = PropertyRepository.ownPageSize,
  }) async => (
    items: listings,
    nextOffset: null,
    countByStatus: {'Active': listings.length},
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size, int listings) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpTestApp(
    tester,
    const MyPropertiesPage(isEmbedded: true),
    overrides: [
      signedInOverride(),
      propertyRepositoryProvider.overrideWithValue(_Server(listings)),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  test('fits as many columns as stay under the card width', () {
    expect(PropertyListLayout.columnCount(300, 360), 1);
    expect(PropertyListLayout.columnCount(360, 360), 1);
    expect(PropertyListLayout.columnCount(1162, 360), 4);
  });

  testWidgets('a phone keeps one full-width card per row', (tester) async {
    await _pumpAt(tester, const Size(390, 844), 2);

    final width = tester.getSize(find.byType(PropertyCard).first).width;
    expect(width, 390 - 32);
  });

  testWidgets('a landscape tablet keeps a lone card card-sized', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1194, 834), 1);

    final width = tester.getSize(find.byType(PropertyCard)).width;
    expect(width, lessThanOrEqualTo(PropertyListLayout.ownCardMaxWidth));
  });

  testWidgets('a tablet lays several cards side by side', (tester) async {
    await _pumpAt(tester, const Size(1194, 834), 5);

    final tops = {
      for (final e in find.byType(PropertyCard).evaluate())
        tester.getTopLeft(find.byWidget(e.widget)).dy,
    };
    expect(tops, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}
