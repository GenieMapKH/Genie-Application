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
