import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/view_models/property_nearby.dart';
import 'package:genie/features/property/presentation/widgets/detail/property_nearby_section.dart';
import 'package:genie/l10n/generated/app_localizations.dart';

/// A full listing as `GET /public/properties/:id` returns it.
PropertyModel _listing({
  List<String> keywords = const ['near_market', 'near_school'],
  List<Map<String, dynamic>> nearby = const [],
  String? searchedAt = '2026-10-17T10:00:00.000Z',
}) => PropertyModel.fromJson({
  'id': 'p-1',
  'title': 'House',
  'price': '1',
  'propertyType': 'House',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
  'keywords': [
    for (final k in keywords) {'keyword': k},
  ],
  'nearbyPlaces': nearby,
  'nearbySearchedAt': searchedAt,
});

Map<String, dynamic> _place(
  String category,
  int rank,
  String name, {
  int straight = 700,
  int? road,
  int? seconds,
}) => {
  'category': category,
  'rank': rank,
  'name': name,
  'lat': 11.55,
  'lng': 104.92,
  'straightMeters': straight,
  'roadMeters': road,
  'driveSeconds': seconds,
};

void main() {
  group('nearbyGroupsOf', () {
    test('one group per tagged category, closest first, even when empty', () {
      final groups = nearbyGroupsOf(
        _listing(
          nearby: [
            _place('market', 1, 'Phsar Far', road: 2500),
            _place('market', 0, 'Phsar Near', road: 900),
          ],
        ),
      );

      expect([for (final g in groups) g.category], ['market', 'school']);
      expect(
        [for (final p in groups[0].places) p.name],
        ['Phsar Near', 'Phsar Far'],
      );
      expect(groups[1].places, isEmpty);
    });

    test('nothing before the server has looked, or without the tags', () {
      expect(nearbyGroupsOf(_listing(searchedAt: null)), isEmpty);
      expect(nearbyGroupsOf(_listing(keywords: ['road_access'])), isEmpty);
    });
  });

  group('PropertyNearbySection', () {
    Future<void> show(WidgetTester tester, PropertyModel property) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            propertyDetailProvider.overrideWith((ref, id) async => property),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PropertyNearbySection(propertyId: 'p-1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows road distance and drive time, or why there is none', (
      tester,
    ) async {
      await show(
        tester,
        _listing(
          keywords: ['near_market', 'near_hospital', 'near_school'],
          nearby: [
            _place(
              'market',
              0,
              'Phsar Toul Tom Poung',
              road: 1640,
              seconds: 361,
            ),
            _place('school', 0, 'Bak Touk High School', straight: 850),
          ],
        ),
      );

      expect(find.text("What's nearby"), findsOneWidget);
      expect(find.text('Phsar Toul Tom Poung'), findsOneWidget);
      expect(find.text('1.6 km'), findsOneWidget);
      expect(find.text('7 min drive'), findsOneWidget);
      // No road found: the straight-line distance, said as such.
      expect(find.text('850 m straight line'), findsOneWidget);
      expect(find.text('None found within 5 km'), findsOneWidget);
    });

    testWidgets('stays hidden for a listing without those tags', (
      tester,
    ) async {
      await show(tester, _listing(keywords: ['corner_land']));

      expect(find.text("What's nearby"), findsNothing);
    });
  });
}
