import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/l10n/l10n.dart';

import 'package:genie/features/property/data/models/property_details.dart';
import 'package:genie/features/property/data/models/property_model.dart';
import 'package:genie/features/property/utils/property_format.dart';

PropertyModel _property({
  String price = '105400',
  String propertyType = 'Land',
  int? bedrooms,
  int? bathrooms,
  double? landSize,
  double? unitSize,
  double? buildingSize,
  double? totalProjectArea,
  String? listingType,
  DateTime? createdAt,
}) {
  return PropertyModel(
    id: 'p1',
    title: 'Test property',
    price: price,
    propertyType: propertyType,
    listingType: listingType,
    status: 'Active',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    landSize: landSize,
    unitSize: unitSize,
    buildingSize: buildingSize,
    details: PropertyDetails(totalProjectArea: totalProjectArea),
  );
}

final _en = lookupAppLocalizations(const Locale('en'));
final _km = lookupAppLocalizations(const Locale('km'));

void main() {
  group('price', () {
    test('formats with a thousands separator and no cents', () {
      expect(PropertyFormat.price('105400'), r'$ 105,400');
    });

    test('falls back to zero for unparseable input', () {
      expect(PropertyFormat.price('not-a-number'), r'$ 0');
    });
  });

  group('size', () {
    test('drops the decimal for whole numbers', () {
      expect(PropertyFormat.size(1670.0), '1670');
    });

    test('keeps one decimal place otherwise', () {
      expect(PropertyFormat.size(83.5), '83.5');
    });
  });

  group('cardSpecLine', () {
    test('shows size and type for land', () {
      final line = PropertyFormat.cardSpecLine(
        _en,
        _property(landSize: 1670, propertyType: 'Land'),
      );

      expect(line, '1670 m² | Land for sale');
    });

    test('shows beds, baths and floor area for a house', () {
      final line = PropertyFormat.cardSpecLine(
        _en,
        _property(
          propertyType: 'House',
          bedrooms: 4,
          bathrooms: 5,
          landSize: 300,
          buildingSize: 115.5,
        ),
      );

      expect(line, '4 bds | 5 ba | 115.5 m² | House for sale');
    });

    test('never shows rooms for a warehouse, even ones saved before', () {
      final line = PropertyFormat.cardSpecLine(
        _en,
        _property(
          propertyType: 'Warehouse',
          bedrooms: 3,
          bathrooms: 2,
          landSize: 2000,
          buildingSize: 1200,
        ),
      );

      expect(line, '1200 m² | Warehouse for sale');
    });

    test('shows a condo with no bedroom as a studio', () {
      final line = PropertyFormat.cardSpecLine(
        _en,
        _property(propertyType: 'Condo', bedrooms: 0, unitSize: 42),
      );

      expect(line, 'Studio | 42 m² | Condo for sale');
    });

    test('omits missing values', () {
      expect(
        PropertyFormat.cardSpecLine(_en, _property(propertyType: 'Condo')),
        'Condo for sale',
      );
    });

    test('says for rent for a rental', () {
      final line = PropertyFormat.cardSpecLine(
        _en,
        _property(landSize: 500, listingType: 'To Let'),
      );

      expect(line, '500 m² | Land for rent');
    });

    test('is in the user language, while the stored type stays English', () {
      final line = PropertyFormat.cardSpecLine(
        _km,
        _property(landSize: 1670, propertyType: 'Land'),
      );

      expect(line, '1670 m² | ដី សម្រាប់លក់');
    });
  });

  group('displaySize', () {
    test('is the one size the type is measured by', () {
      expect(_property(landSize: 2000, buildingSize: 1200).displaySize, 2000);
      for (final type in ['House', 'Building', 'Warehouse']) {
        expect(
          _property(
            propertyType: type,
            landSize: 2000,
            buildingSize: 1200,
          ).displaySize,
          1200,
        );
      }
      expect(
        _property(propertyType: 'Business for Sale', landSize: 80).displaySize,
        80,
      );
      expect(
        _property(propertyType: 'Condo', unitSize: 50, landSize: 9).displaySize,
        50,
      );
      expect(
        _property(propertyType: 'Borey', totalProjectArea: 50000).displaySize,
        50000,
      );
    });

    test("is null when the type's size is missing or zero", () {
      expect(
        _property(propertyType: 'House', landSize: 300).displaySize,
        isNull,
      );
      expect(_property(landSize: 0).displaySize, isNull);
    });
  });

  group('cardPrice', () {
    test('is the price for a sale', () {
      expect(PropertyFormat.cardPrice(_en, _property()), r'$ 105,400');
    });

    test('is per month for a rental', () {
      expect(
        PropertyFormat.cardPrice(
          _en,
          _property(price: '500', listingType: 'Rent'),
        ),
        r'$ 500 / month',
      );
    });

    test('starts from the price for a Borey', () {
      expect(
        PropertyFormat.cardPrice(_en, _property(propertyType: 'Borey')),
        r'From $ 105,400',
      );
    });
  });

  group('bed and bath labels', () {
    test('singularise for one', () {
      expect(_en.propertyBedroomCount(1), '1 Bed');
      expect(_en.propertyBathroomCount(1), '1 Bath');
    });

    test('pluralise beyond one', () {
      expect(_en.propertyBedroomCount(2), '2 Beds');
      expect(_en.propertyBathroomCount(3), '3 Baths');
    });
  });

  group('isNew', () {
    test('is true for a listing created today', () {
      expect(_property(createdAt: DateTime.now()).isNew, isTrue);
    });

    test('is false for a listing older than two weeks', () {
      final old = DateTime.now().subtract(const Duration(days: 20));
      expect(_property(createdAt: old).isNew, isFalse);
    });
  });

  group('typeIconPath', () {
    test('maps known types to their icons', () {
      expect(
        PropertyFormat.typeIconPath('House'),
        'assets/icons/property_house.svg',
      );
      expect(
        PropertyFormat.typeIconPath('Warehouse'),
        'assets/icons/property_warehouse.svg',
      );
    });

    test('falls back to the land icon for unknown types', () {
      expect(
        PropertyFormat.typeIconPath('Spaceship'),
        'assets/icons/property_land.svg',
      );
    });
  });
}
