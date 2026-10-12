import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/property/presentation/view_models/add_property_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  ValidationResult validate({
    String title = 'My plot',
    String price = '100',
    String propertyType = 'Land',
    String listingSetting = 'Sell',
    String landSize = '500',
    String buildingSize = '',
    String unitSize = '',
  }) {
    return container
        .read(addPropertyControllerProvider.notifier)
        .validatePropertyForm(
          title: title,
          price: price,
          propertyType: propertyType,
          listingSetting: listingSetting,
          landSize: landSize,
          buildingSize: buildingSize,
          unitSize: unitSize,
        );
  }

  test('a complete land listing is valid', () {
    expect(validate().isValid, isTrue);
  });

  test('the title is checked first', () {
    final result = validate(title: '  ', price: '');

    expect(result.firstErrorField, PropertyField.title);
  });

  test('no type chosen is validated like Land', () {
    expect(
      validate(propertyType: '', landSize: '').firstErrorField,
      PropertyField.landSize,
    );
  });

  test('errors are reported in form order', () {
    final result = validate(price: '', listingSetting: '', landSize: '');

    expect(result.firstErrorField, PropertyField.price);
    expect(
      validate(listingSetting: '', landSize: '').firstErrorField,
      PropertyField.listingSettings,
    );
  });

  test('houses, warehouses and buildings also need a building size', () {
    for (final type in ['House', 'Warehouse', 'Building']) {
      final result = validate(propertyType: type, buildingSize: '');

      expect(result.firstErrorField, PropertyField.buildingSize, reason: type);
    }
  });

  test('condos need a unit size but not a land size', () {
    final missingUnit = validate(
      propertyType: 'Condo',
      landSize: '',
      unitSize: '',
    );
    final complete = validate(
      propertyType: 'Condo',
      landSize: '',
      unitSize: '60',
    );

    expect(missingUnit.firstErrorField, PropertyField.unitSize);
    expect(complete.isValid, isTrue);
  });

  test('a borey only needs a title', () {
    final result = validate(
      propertyType: 'Borey',
      price: '',
      listingSetting: '',
      landSize: '',
    );

    expect(result.isValid, isTrue);
  });

  test('business for sale asks for land size before listing setting', () {
    final result = validate(
      propertyType: 'Business for Sale',
      landSize: '',
      listingSetting: '',
    );

    expect(result.firstErrorField, PropertyField.landSize);
  });
}
