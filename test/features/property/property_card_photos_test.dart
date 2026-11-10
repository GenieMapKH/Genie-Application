import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_card.dart';
import 'package:tilomnov/features/property/presentation/widgets/property_image_gallery.dart';

import '../../support/test_app.dart';

Future<void> _pumpCard(WidgetTester tester, int photos) => pumpTestApp(
  tester,
  Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(
        width: 320,
        child: PropertyCard(
          property: PropertyModel(
            id: 'listing',
            title: 'Land',
            price: '10000',
            propertyType: 'Land',
            status: 'Active',
            createdAt: DateTime(2026),
            imageUrls: List.filled(
              photos,
              'assets/images/brand/logo_on_light.png',
            ),
          ),
          onOptionsTapped: () {},
          onStatusTapped: () {},
          onInsightsTapped: () {},
        ),
      ),
    ),
  ),
);

Finder get _dots => find.descendant(
  of: find.byType(PropertyImageGallery),
  matching: find.byType(AnimatedContainer),
);

void main() {
  for (final (photos, dots) in [(0, 0), (1, 0), (2, 2), (3, 3), (7, 5)]) {
    testWidgets('$photos photos shows $dots gallery dots', (tester) async {
      await _pumpCard(tester, photos);
      await tester.pumpAndSettle();

      expect(_dots, findsNWidgets(dots));
      expect(find.byType(PageView), photos > 1 ? findsOneWidget : findsNothing);
      if (photos == 0) {
        expect(find.byType(PropertyImagePlaceholder), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('swiping the actual photos updates the active dot', (
    tester,
  ) async {
    await _pumpCard(tester, 3);
    await tester.pumpAndSettle();
    expect(tester.getSize(_dots.at(0)).width, 20);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(tester.getSize(_dots.at(0)).width, 12);
    expect(tester.getSize(_dots.at(1)).width, 20);
  });
}
