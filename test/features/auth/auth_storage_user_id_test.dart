import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';

String _jwt(Map<String, Object?> payload) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part(payload)}.signature';
}

void main() {
  test('password-only admin tokens require a new email login', () {
    final token = _jwt({'sub': 'owner', 'role': 'admin'});
    expect(AuthStorage.isAdminAccessToken(token), isFalse);
    expect(AuthStorage.needsAdminEmailVerification(token), isTrue);
  });

  test('only the server-issued admin role selects the admin dashboard', () {
    expect(
      AuthStorage.isAdminAccessToken(
        _jwt({'sub': 'owner', 'role': 'admin', 'adminMfa': true}),
      ),
      isTrue,
    );
    expect(
      AuthStorage.isAdminAccessToken(_jwt({'sub': 'ordinary', 'role': 'user'})),
      isFalse,
    );
    expect(
      AuthStorage.isAdminAccessToken(
        _jwt({'sub': 'ordinary', 'email': 'owner@example.com'}),
      ),
      isFalse,
    );
    expect(AuthStorage.isAdminAccessToken(null), isFalse);
  });
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

  group('isTokenExpired', () {
    final now = DateTime(2026, 10, 24, 12);
    int secondsAt(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

    test('is true once exp has passed, or is under the leeway away', () {
      final past = _jwt({'exp': secondsAt(now.subtract(Duration(minutes: 1)))});
      final soon = _jwt({'exp': secondsAt(now.add(Duration(seconds: 10)))});
      expect(AuthStorage.isTokenExpired(past, now: now), isTrue);
      expect(AuthStorage.isTokenExpired(soon, now: now), isTrue);
    });

    test('is false for a token with time left', () {
      final fresh = _jwt({'exp': secondsAt(now.add(Duration(minutes: 10)))});
      expect(AuthStorage.isTokenExpired(fresh, now: now), isFalse);
    });

    test('leaves an unreadable token to the server', () {
      expect(AuthStorage.isTokenExpired('not-a-jwt', now: now), isFalse);
      expect(AuthStorage.isTokenExpired(_jwt({'sub': 'x'}), now: now), isFalse);
    });
  });
}
