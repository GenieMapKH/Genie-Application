import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tilomnov/core/logging/app_logger.dart';

/// What a screen last read from the server, kept on this device as the JSON
/// the server sent, so the screen can show it at once on the next start and
/// while there is no internet. One copy per name and account: someone else
/// signing in on the same phone never sees it.
///
/// Keeping is a convenience: a copy that cannot be kept or read is logged
/// and skipped, never failing what the screen asked for.
class KeptCopyStore {
  /// Whose copies these are: an account id, or null to keep nothing.
  final Future<String?> Function() account;

  const KeptCopyStore({required this.account});

  static String _key(String name, String account) => '$name.$account';

  /// The copy of [name], made into what the screen shows by [parse]. Null
  /// when none is kept or it can no longer be read (kept by an older build).
  Future<T?> read<T>(
    String name, {
    required FutureOr<T> Function(Map<String, dynamic> json) parse,
  }) async {
    try {
      final owner = await account();
      if (owner == null) return null;
      final preferences = await SharedPreferences.getInstance();
      final json = preferences.getString(_key(name, owner));
      if (json == null) return null;
      return await parse(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      // The fresh copy replaces it.
      AppLogger.error('The kept copy of $name could not be read', e);
      return null;
    }
  }

  /// Keeps [json] as the copy of [name].
  Future<void> write(String name, Map<String, dynamic> json) async {
    try {
      final owner = await account();
      if (owner == null) return;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_key(name, owner), jsonEncode(json));
    } catch (e) {
      AppLogger.error('The copy of $name could not be kept', e);
    }
  }
}
