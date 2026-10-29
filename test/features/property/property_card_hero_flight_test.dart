import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/saved_property_card.dart';
import 'package:tilomnov/shared/transitions/app_page_route.dart';

import '../../support/test_app.dart';

final _property = PropertyModel(
  id: 'p-1',
  title: 'Near Ring Road 3',
  price: '100000',
  propertyType: 'Land',
  status: 'Active',
  createdAt: DateTime(2026),
  ownerId: 'owner',
);

Widget _card(Size size, VoidCallback onTap) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox.fromSize(
    size: size,
    child: SavedPropertyCard(property: _property, onTap: onTap),
  ),
);

void main() {
  // The feed's wide card flying to a profile's narrow one, and back: both
  // cards keep their own layout and fade into each other, so their text is
  // never laid out again at an in-between width.
  testWidgets('a card flies to the same listing\'s card as both, crossfaded', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: _card(
            const Size(358, 320),
            () => Navigator.of(context).push(
              AppPageRoute<void>(
                page: Scaffold(
                  body: Builder(
                    builder: (context) => _card(
                      const Size(170, 250),
                      () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Near Ring Road 3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Near Ring Road 3'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('Near Ring Road 3'), findsOneWidget);

    await tester.tap(find.text('Near Ring Road 3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Near Ring Road 3'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('Near Ring Road 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
