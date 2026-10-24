import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/feed/presentation/widgets/feed_listing_card.dart';
import 'package:genie/features/notifications/models/push_message.dart';
import 'package:genie/features/property/data/models/property_model.dart';

import '../../support/test_app.dart';

Map<String, dynamic> _json({Object? droppedAt, Object? previousPrice}) => {
  'id': 'p-1',
  'title': 'Villa near Riverside',
  'price': '110000',
  'propertyType': 'Villa',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
  'priceDroppedAt': droppedAt,
  'previousPrice': previousPrice,
  'user': {'id': 'u-1', 'name': 'Dara'},
};

void main() {
  test('reads a price drop, shown for two weeks', () {
    final property = PropertyModel.fromJson(
      _json(droppedAt: '2026-10-20T00:00:00.000Z', previousPrice: '120000.00'),
    );

    expect(property.previousPrice, 120000);
    expect(
      property.recentPreviousPrice(now: DateTime.utc(2026, 10, 24)),
      120000,
    );
    expect(
      property.recentPreviousPrice(now: DateTime.utc(2026, 11, 5)),
      isNull,
    );
  });

  test('a listing without a drop shows none', () {
    final property = PropertyModel.fromJson(_json());
    expect(property.priceDroppedAt, isNull);
    expect(property.recentPreviousPrice(), isNull);
  });

  test('pushes about followed and saved listings open the listing', () {
    for (final type in ['followed_listing', 'price_drop', 'listing_sold']) {
      final push = PushMessage.fromData({'type': type, 'propertyId': 'p-1'});
      expect(push, isA<ListingAlertPush>(), reason: type);
    }
  });

  testWidgets('a feed card says the price dropped, with the old price', (
    tester,
  ) async {
    final property = PropertyModel.fromJson(
      _json(
        droppedAt: DateTime.now()
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        previousPrice: '120000',
      ),
    );

    await pumpTestApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: FeedListingCard(
            property: property,
            isFavorite: false,
            onOpen: () {},
            onOpenOwner: (_) {},
            onFavoriteToggled: () {},
          ),
        ),
      ),
    );

    expect(find.text('Price dropped'), findsOneWidget);
    expect(find.text('\$ 120,000'), findsOneWidget);
  });
}
