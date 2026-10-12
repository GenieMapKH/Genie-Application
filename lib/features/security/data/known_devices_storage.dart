import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, on this device, which signed-in devices of an account the
/// user has already been shown. Kept per account: two people sharing a phone
/// do not see each other's lists.
class KnownDevicesStorage {
  static String _key(String userId) => 'security.known_devices.$userId';

  /// The session ids seen so far. Null when this device has never looked.
  Future<Set<String>?> read(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key(userId))?.toSet();
  }

  Future<void> write(String userId, Set<String> sessionIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key(userId), sessionIds.toList());
  }
}
