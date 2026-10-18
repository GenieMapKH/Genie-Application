import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/l10n/l10n.dart';

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
  DateTime? createdAt,
}) {
  return PropertyModel(
    id: 'p1',
    title: 'Test property',
    price: price,
    propertyType: propertyType,
    status: 'Active',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    landSize: landSize,
    unitSize: unitSize,
    buildingSize: buildingSize,
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

    test('includes beds and baths for built property', () {
      final line = PropertyFormat.cardSpecLine(
        _en,
        _property(
          propertyType: 'House',
          bedrooms: 4,
          bathrooms: 5,
          landSize: 115.5,
        ),
      );

      expect(line, '4 bds | 5 ba | 115.5 m² | House for sale');
    });

    test('omits zero and missing values', () {
      final line = PropertyFormat.cardSpecLine(
        _en,
        _property(propertyType: 'Condo', bedrooms: 0),
      );

      expect(line, 'Condo for sale');
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
    test('prefers land size, then unit, then building', () {
      expect(_property(landSize: 100, unitSize: 50).displaySize, 100);
      expect(_property(unitSize: 50, buildingSize: 25).displaySize, 50);
      expect(_property(buildingSize: 25).displaySize, 25);
      expect(_property().displaySize, isNull);
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
