import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/repositories/property_repository.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_providers.dart';

import '../../support/test_app.dart';

const _square = [
  LatLng(11.5500, 104.9200),
  LatLng(11.5500, 104.92092),
  LatLng(11.5509, 104.92092),
  LatLng(11.5509, 104.9200),
];

/// Records what each new listing is created with.
class _Server extends PropertyRepository {
  final created = <Map<String, dynamic>>[];

  _Server() : super(Dio());

  @override
  Future<PropertyModel> create(Map<String, dynamic> data) async {
    created.add(data);
    return _listing(data['status'] as String);
  }

  @override
  Future<PropertyModel> updateBoundary(
    String id,
    List<Map<String, double>> boundaryPoints,
  ) async => _listing(created.last['status'] as String);

  static PropertyModel _listing(String status) => PropertyModel.fromJson({
    'id': 'p-new',
    'title': 'Plot',
    'price': '0',
    'propertyType': 'Land',
    'status': status,
    'createdAt': '2026-10-29T00:00:00.000Z',
  });
}

/// Opens the add page from a launcher, so popping it can be seen.
Future<void> _openAddPage(WidgetTester tester, _Server server) async {
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AddPropertyPage(
              boundaryPoints: _square,
              propertyArea: 10000,
            ),
          ),
        ),
        child: const Text('open'),
      ),
    ),
    overrides: [propertyRepositoryProvider.overrideWithValue(server)],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new listing offers Archive and Publish, and no header Save', (
    tester,
  ) async {
    await _openAddPage(tester, _Server());

    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    // Archive is on the left of Publish.
    expect(
      tester.getCenter(find.text('Archive')).dx,
      lessThan(tester.getCenter(find.text('Publish')).dx),
    );
  });

  testWidgets('Archive keeps the new listing private and closes the page', (
    tester,
  ) async {
    final server = _Server();
    await _openAddPage(tester, server);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(server.created.single['status'], 'Draft');
    expect(find.byType(AddPropertyPage), findsNothing);
    // Let the confirmation toast finish.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Publish refuses an incomplete listing', (tester) async {
    final server = _Server();
    await _openAddPage(tester, server);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(server.created, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('editing offers one Save changes button', (tester) async {
    await pumpTestApp(
      tester,
      AddPropertyPage.edit(
        PropertyModel.fromJson({
          'id': 'p-1',
          'title': 'Plot',
          'price': '50000',
          'propertyType': 'Land',
          'listingType': 'Sale',
          'status': 'Active',
          'createdAt': '2026-10-01T00:00:00.000Z',
          'boundaryPoints': [
            for (final p in _square) {'lat': p.latitude, 'lng': p.longitude},
          ],
        }),
      ),
    );
    await tester.pump();

    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Archive'), findsNothing);
    expect(find.text('Publish'), findsNothing);
  });
}
