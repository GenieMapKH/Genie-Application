import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/data/models/property_details.dart';
import 'package:tilomnov/features/property/presentation/widgets/detail/sections/property_contact_identity.dart';
import '../../support/test_app.dart';

void main() {
  PropertyModel listing({bool verified = false}) => PropertyModel(
    id: 'p',
    title: 'Home',
    price: '100',
    propertyType: 'Land',
    status: 'Active',
    createdAt: DateTime(2026),
    ownerEmail: 'seller@example.com',
    ownerPhone: '+85512345678',
    ownerEmailVerified: verified,
    ownerPhoneVerified: verified,
  );

  testWidgets('shows both contacts and honest unverified status', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Scaffold(body: PropertyContactIdentity(property: listing())),
    );
    expect(find.text('seller@example.com'), findsOneWidget);
    expect(find.text('+85512345678'), findsOneWidget);
    expect(find.text('Not verified'), findsNWidgets(2));
  });

  testWidgets('shows server verification status on each contact', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: PropertyContactIdentity(property: listing(verified: true)),
      ),
    );
    expect(find.text('Verified'), findsNWidgets(2));
    expect(
      listing(verified: true).copyWith(title: 'Edited').ownerPhoneVerified,
      isTrue,
    );
  });

  testWidgets('another listing phone never inherits account verification', (
    tester,
  ) async {
    final property = listing(verified: true).copyWith(
      details: const PropertyDetails(
        contactPhone: '098765432',
        additionalContactPhones: ['012 345 678'],
      ),
    );
    await pumpTestApp(
      tester,
      Scaffold(body: PropertyContactIdentity(property: property)),
    );
    expect(find.text('Verified'), findsNWidgets(2));
    expect(find.text('Not verified'), findsOneWidget);
    expect(find.text('+85512345678'), findsOneWidget);
  });

  test('older API responses never imply verified contacts', () {
    final property = PropertyModel.fromJson({
      'id': 'p',
      'title': 'Home',
      'price': '100',
      'propertyType': 'Land',
      'status': 'Active',
      'createdAt': '2026-01-01T00:00:00Z',
      'user': {'email': 'seller@example.com', 'phone': '+85512345678'},
    });
    expect(property.ownerEmailVerified, isFalse);
    expect(property.ownerPhoneVerified, isFalse);
  });
}
