import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_details.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/actions/call_owner.dart';

PropertyModel _listing({String? listingPhone, String? ownerPhone}) =>
    PropertyModel(
      id: 'p-1',
      title: 'Near Ring Road 3',
      price: '100000',
      propertyType: 'Land',
      status: 'Active',
      createdAt: DateTime(2026),
      ownerPhone: ownerPhone,
      details: PropertyDetails(contactPhone: listingPhone),
    );

void main() {
  for (final method in PropertyCallMethod.values) {
    testWidgets('Call Now offers both methods and returns ${method.name}', (
      tester,
    ) async {
      PropertyCallMethod? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await choosePropertyCallMethod(context);
              },
              child: const Text('Call Now'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Call Now'));
      await tester.pumpAndSettle();
      expect(find.text('Call in Tilomnov'), findsOneWidget);
      expect(find.text('Use phone dialer'), findsOneWidget);
      await tester.tap(
        find.text(
          method == PropertyCallMethod.inApp
              ? 'Call in Tilomnov'
              : 'Use phone dialer',
        ),
      );
      await tester.pumpAndSettle();
      expect(selected, method);
    });
  }

  testWidgets('dismissing the choice places no call', (tester) async {
    var finished = false;
    PropertyCallMethod? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await choosePropertyCallMethod(context);
              finished = true;
            },
            child: const Text('Call Now'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Call Now'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
    expect(selected, isNull);
  });

  test("dials the number written on the listing before the owner's", () {
    expect(
      callNumberOf(_listing(listingPhone: '012 345 678', ownerPhone: '099')),
      '012 345 678',
    );
  });

  test("falls back to the owner's number", () {
    expect(
      callNumberOf(_listing(listingPhone: '  ', ownerPhone: '099')),
      '099',
    );
  });

  test('has nothing to dial for a guest, who is sent no numbers', () {
    expect(callNumberOf(_listing()), isNull);
  });
}
