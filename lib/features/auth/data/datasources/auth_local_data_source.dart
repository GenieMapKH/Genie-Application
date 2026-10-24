import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static const _guestSessionKey = 'guest_session_id';

  static final _signedIn = ValueNotifier<bool>(false);

  /// Whether tokens are stored. Follows every save and clear, whoever makes
  /// it (sign-in, sign-out, a renewal the server refused), so nothing can
  /// go on treating this device as signed in after the tokens are gone.
  static ValueListenable<bool> get signedIn => _signedIn;

  /// Reads the stored session once, before the first screen asks about it.
  static Future<void> load() async {
    _signedIn.value = await getAccessToken() != null;
  }

  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
    _signedIn.value = true;
  }

  static Future<void> saveGuestSessionId(String id) async {
    await _storage.write(key: _guestSessionKey, value: id);
  }

  static Future<String?> getAccessToken() async =>
      await _storage.read(key: _accessTokenKey);
  static Future<String?> getRefreshToken() async =>
      await _storage.read(key: _refreshTokenKey);
  static Future<String?> getGuestSessionId() async =>
      await _storage.read(key: _guestSessionKey);

  /// The signed-in account's id: the `sub` of the stored access token. Null
  /// when signed out. Only for keeping data apart per account on this
  /// device; the server checks the token itself.
  static Future<String?> signedInUserId() async =>
      userIdOfToken(await getAccessToken());

  /// The `sub` of the JWT [token], or null when it is not a readable JWT.
  @visibleForTesting
  static String? userIdOfToken(String? token) {
    final parts = token?.split('.');
    if (parts == null || parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final sub = payload is Map ? payload['sub'] : null;
      return sub is String && sub.isNotEmpty ? sub : null;
    } on FormatException {
      return null;
    }
  }

  static Future<void> clearTokens() async {
    // Said first: screens must stop acting for the user at once, not after
    // the storage answers.
    _signedIn.value = false;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> clearGuestSessionId() async {
    await _storage.delete(key: _guestSessionKey);
  }
}
