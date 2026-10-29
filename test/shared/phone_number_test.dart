import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/shared/utils/phone_number.dart';

void main() {
  test('reads every common spelling of a Cambodian number the same way', () {
    for (final typed in [
      '012 345 678',
      '012-345-678',
      '(012) 345.678',
      '12345678',
      '85512345678',
      '+85512345678',
      '+855 012 345 678',
      '00855 12 345 678',
    ]) {
      expect(normalizePhoneNumber(typed), '+85512345678', reason: typed);
    }
    expect(normalizePhoneNumber('097 1234 567'), '+855971234567');
  });

  test('keeps other countries when they carry their code', () {
    expect(normalizePhoneNumber('+66 81 234 5678'), '+66812345678');
  });

  test('refuses what is not a phone number', () {
    for (final typed in [
      '',
      '012',
      '0123456789012',
      'abc',
      "012345678' OR '1'='1",
      '<b>012345678</b>',
      'john@example.com',
    ]) {
      expect(normalizePhoneNumber(typed), isNull, reason: typed);
    }
  });
}
