/// The phone number in the form the server stores it (E.164, `+85512345678`),
/// or null when [input] is not a phone number. Same rule as the server's
/// `normalizePhoneNumber`: without a country code a number is Cambodian, so
/// `012 345 678`, `12345678` and `+855 012 345 678` are all `+85512345678`.
/// Other countries need their `+` or `00` prefix.
String? normalizePhoneNumber(String input) {
  var digits = input.replaceAll(RegExp(r'[\s().-]'), '');
  var international = false;
  if (digits.startsWith('+')) {
    international = true;
    digits = digits.substring(1);
  } else if (digits.startsWith('00')) {
    international = true;
    digits = digits.substring(2);
  }
  if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return null;

  if (international && !digits.startsWith(_cambodiaCode)) {
    final e164 = '+$digits';
    return RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(e164) ? e164 : null;
  }

  var national = digits;
  if (international ||
      (digits.startsWith(_cambodiaCode) && digits.length >= 11)) {
    national = digits.substring(_cambodiaCode.length);
  }
  // "+855 0..." is common: the trunk 0 is never part of the number.
  if (national.startsWith('0')) national = national.substring(1);
  return RegExp(r'^[1-9][0-9]{7,8}$').hasMatch(national)
      ? '+$_cambodiaCode$national'
      : null;
}

const _cambodiaCode = '855';
