import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/property/data/models/property_model.dart';
import 'package:tilomnov/features/property/presentation/view_models/property_form_input.dart';

/// A listing as the server returns it.
PropertyModel _saved(Map<String, dynamic> fields) => PropertyModel.fromJson({
  'id': 'p-1',
  'title': 'Saved',
  'price': '0',
  'status': 'Active',
  'createdAt': '2026-10-01T00:00:00.000Z',
  ...fields,
});

void main() {
  group('request body', () {
    test('a condo sends every detail, with dropdown labels as values', () {
      const input = PropertyFormInput(
        propertyType: 'Condo',
        title: '  Riverside condo ',
        price: '120,000',
        listingType: 'Rent',
        unitSize: '72.5',
        floorNumber: '10+',
        floors: '30',
        bedrooms: 'Studio',
        bathrooms: '1',
        balcony: 'Yes',
        furnished: 'Fully Furnished',
        completionStatus: 'Completed',
        viewType: 'River View',
        maintenanceFee: '80',
        contactPhone: ' 012 345 678 ',
        keywords: {'water_supply', 'near_market'},
      );

      expect(input.toRequestBody(), {
        ...input.toRequestBody(),
        'title': 'Riverside condo',
        'price': 120000.0,
        'propertyType': 'Condo',
        'listingType': 'Rent',
        'titleType': 'Hard Title',
        'unitSize': 72.5,
        'floorNumber': 10,
        'floors': 30,
        'bedrooms': 0,
        'bathrooms': 1,
        'hasBalcony': true,
        'hasParking': null,
        'furnishing': 'Fully Furnished',
        'viewType': 'River View',
        'maintenanceFee': 80.0,
        'contactPhone': '012 345 678',
        'description': null,
        'keywords': ['near_market', 'water_supply'],
      });
    });

    test('a Borey project is priced by its starting price', () {
      const input = PropertyFormInput(
        propertyType: 'Borey',
        price: '999',
        startingPrice: '45000',
        totalUnitsText: '320',
        totalUnits: '5',
      );

      final body = input.toRequestBody();
      expect(body['price'], 45000.0);
      expect(body['totalUnits'], 320);
    });

    test('a lease in years is sent in months', () {
      const input = PropertyFormInput(
        propertyType: 'Business for Sale',
        leaseRemaining: '3',
        leaseUnit: 'Years',
      );

      expect(input.toRequestBody()['leaseRemainingMonths'], 36);
    });

    test('empty fields are sent as null so an edit can clear them', () {
      final body = const PropertyFormInput(listingType: '').toRequestBody();

      expect(body['title'], 'Untitled Property');
      expect(body['price'], 0);
      expect(body['listingType'], isNull);
      expect(body['landSize'], isNull);
      expect(body['bedrooms'], isNull);
      expect(body['keywords'], isEmpty);
    });
  });

  group('editing opens the form as it was filled', () {
    test('a condo round-trips', () {
      final property = _saved({
        'propertyType': 'Condo',
        'price': '120000',
        'listingType': 'Rent',
        'titleType': 'Soft Title',
        'unitSize': '72.5',
        'bedrooms': 0,
        'bathrooms': 2,
        'floorNumber': 14,
        'floors': 30,
        'hasBalcony': false,
        'maintenanceFee': '80.00',
        'description': 'Nice view',
        'contactPhone': '012345678',
        'keywords': [
          {'keyword': 'near_market'},
        ],
      });

      final input = PropertyFormInput.fromProperty(property);

      expect(input.price, '120000');
      expect(input.listingType, 'Rent');
      expect(input.titleType, 'Soft Title');
      expect(input.unitSize, '72.5');
      expect(input.bedrooms, 'Studio');
      expect(input.floorNumber, '10+');
      expect(input.floors, '10+');
      expect(input.balcony, 'No');
      expect(input.maintenanceFee, '80');
      expect(input.keywords, {'near_market'});
      expect(input.toRequestBody()['bedrooms'], 0);
      expect(input.toRequestBody()['description'], 'Nice view');
    });

    test('a house with no bedrooms shows "0", not "Studio"', () {
      final input = PropertyFormInput.fromProperty(
        _saved({'propertyType': 'House', 'bedrooms': 0}),
      );
      expect(input.bedrooms, '0');
    });

    test('a Borey project shows its price as the starting price', () {
      final input = PropertyFormInput.fromProperty(
        _saved({'propertyType': 'Borey', 'price': '45000', 'totalUnits': 320}),
      );

      expect(input.startingPrice, '45000');
      expect(input.price, '');
      expect(input.totalUnitsText, '320');
      expect(input.totalUnits, isNull);
    });

    test('a lease of whole years shows in years', () {
      PropertyFormInput withLease(int months) => PropertyFormInput.fromProperty(
        _saved({
          'propertyType': 'Business for Sale',
          'leaseRemainingMonths': months,
        }),
      );

      expect(withLease(24).leaseRemaining, '2');
      expect(withLease(24).leaseUnit, 'Years');
      expect(withLease(18).leaseRemaining, '18');
      expect(withLease(18).leaseUnit, 'Months');
    });

    test('a listing saved before listing types existed defaults to Sale', () {
      final input = PropertyFormInput.fromProperty(
        _saved({'propertyType': 'Land'}),
      );
      expect(input.listingType, 'Sale');
    });
  });
}
