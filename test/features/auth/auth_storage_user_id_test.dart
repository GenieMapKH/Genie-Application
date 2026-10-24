import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';

String _jwt(Map<String, Object?> payload) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part(payload)}.signature';
}

void main() {
  test('reads the account id from the token subject', () {
    expect(AuthStorage.userIdOfToken(_jwt({'sub': 'user-42'})), 'user-42');
  });

  test('is null for anything that is not a readable token', () {
    expect(AuthStorage.userIdOfToken(null), isNull);
    expect(AuthStorage.userIdOfToken('not-a-jwt'), isNull);
    expect(AuthStorage.userIdOfToken('a.%%%.c'), isNull);
    expect(AuthStorage.userIdOfToken(_jwt({'sub': ''})), isNull);
    expect(AuthStorage.userIdOfToken(_jwt({'name': 'no subject'})), isNull);
  });
}
