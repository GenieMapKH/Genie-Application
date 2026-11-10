import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/presentation/admin_property_card.dart';
import 'package:tilomnov/features/admin/presentation/admin_records_page.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_nearby.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_route.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/property_detail_sheet.dart';
import 'package:tilomnov/features/property/presentation/widgets/saved_property_card.dart';
import '../../support/test_app.dart';

final _json = <String, dynamic>{
  'id': 'p1',
  'title': 'Riverside plot',
  'price': 45000,
  'propertyType': 'Land',
  'status': 'Active',
  'createdAt': '2026-11-01T00:00:00Z',
  'images': <dynamic>[],
};

void main() {
  testWidgets('Explore records use the saved-property grid on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final server = StubServer.always(
      200,
      jsonEncode({
        'items': [
          _json,
          {..._json, 'id': 'p2'},
        ],
        'nextOffset': null,
      }),
    );
    await pumpTestApp(
      tester,
      const AdminRecordsPage(
        section: 'all-listings',
        title: 'Explore properties',
      ),
      overrides: [apiClientProvider.overrideWithValue(server.dio)],
    );
    await tester.pumpAndSettle();
    final cards = find.byType(SavedPropertyCard);
    expect(cards, findsNWidgets(2));
    expect(tester.getTopLeft(cards.first).dy, tester.getTopLeft(cards.last).dy);
    expect(tester.getSize(cards.first).width, lessThan(200));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'admin cards reuse the saved card, stay card-sized, and allow draft moderation',
    (tester) async {
      var opened = false;
      await pumpTestApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: AdminPropertyCard(
              property: {..._json, 'status': 'Draft'},
              onTap: () => opened = true,
            ),
          ),
        ),
      );
      expect(find.byType(SavedPropertyCard), findsOneWidget);
      expect(
        tester.getSize(find.byType(SavedPropertyCard)).width,
        lessThanOrEqualTo(260),
      );
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Unavailable'), findsNothing);
      await tester.tap(find.text('Riverside plot'));
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tapping an admin card opens the shared popup route with its matching hero',
    (tester) async {
      final property = PropertyModel.fromJson(_json);
      final server = StubServer.always(200, '[]');
      await pumpTestApp(
        tester,
        Scaffold(body: AdminPropertyCard(property: _json)),
        overrides: [
          signedInOverride(signedIn: false),
          propertyRepositoryProvider.overrideWithValue(
            PropertyRepository(server.dio),
          ),
          propertyDetailProvider.overrideWith((ref, id) async => property),
        ],
      );
      final card = tester.widget<SavedPropertyCard>(
        find.byType(SavedPropertyCard),
      );
      await tester.tap(find.text('Riverside plot'));
      await tester.pumpAndSettle();
      final sheet = tester.widget<PropertyDetailSheet>(
        find.byType(PropertyDetailSheet),
      );
      expect(sheet.heroTag, card.heroTag);
      expect(
        ModalRoute.of(tester.element(find.byType(PropertyDetailSheet))),
        isA<PropertyDetailRoute>(),
      );
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );
}
