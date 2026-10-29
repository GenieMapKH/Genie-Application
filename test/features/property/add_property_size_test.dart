import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page.dart';
import 'package:tilomnov/features/property/presentation/screens/add_property/add_property_page_form_binding.dart';
import 'package:tilomnov/l10n/generated/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// About 100 m x 100 m in Phnom Penh.
const _square = [
  LatLng(11.5500, 104.9200),
  LatLng(11.5500, 104.92092),
  LatLng(11.5509, 104.92092),
  LatLng(11.5509, 104.9200),
];

Future<AddPropertyPageState> _open(
  WidgetTester tester,
  AddPropertyPage page,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pump();
  return tester.state<AddPropertyPageState>(find.byType(AddPropertyPage));
}

PropertyModel _land({String? landSize}) => PropertyModel.fromJson({
  'id': 'p-1',
  'title': 'Plot',
  'price': '50000',
  'propertyType': 'Land',
  'listingType': 'Sale',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
  'landSize': landSize,
  'boundaryPoints': [
    for (final p in _square) {'lat': p.latitude, 'lng': p.longitude},
  ],
});

void main() {
  testWidgets('a drawn area is filled in as plain m², and saved as a number', (
    tester,
  ) async {
    final state = await _open(
      tester,
      const AddPropertyPage(boundaryPoints: _square, propertyArea: 10123.46),
    );

    expect(state.landSizeController.text, '10123.5');
    expect(state.collectFormInput().toRequestBody()['landSize'], 10123.5);
  });

  testWidgets('editing shows the saved size', (tester) async {
    final state = await _open(
      tester,
      AddPropertyPage.edit(_land(landSize: '400.00')),
    );

    expect(state.landSizeController.text, '400');
  });

  testWidgets('editing a listing whose size was lost measures its boundary', (
    tester,
  ) async {
    final state = await _open(tester, AddPropertyPage.edit(_land()));

    final measured = double.parse(state.landSizeController.text);
    expect(measured, closeTo(10000, 300));
  });

  testWidgets('"Auto from map" fills the size from the boundary', (
    tester,
  ) async {
    final state = await _open(
      tester,
      AddPropertyPage.edit(_land(landSize: '1')),
    );

    await tester.ensureVisible(find.text('Auto from map'));
    await tester.tap(find.text('Auto from map'));
    await tester.pump();

    expect(double.parse(state.landSizeController.text), closeTo(10000, 300));
  });
}
