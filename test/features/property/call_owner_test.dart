import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/data/models/property_details.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/presentation/widgets/detail/actions/call_owner.dart';

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
